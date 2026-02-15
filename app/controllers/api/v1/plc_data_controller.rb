module Api
  module V1
    class PlcDataController < Api::V1::BaseController
      # POST /api/v1/plc_data
      # Receives measurement data forwarded from the PLC ingestion service.
      #
      # Expected payload:
      #   {
      #     from_email: "plc_username",
      #     data: "2025-05-13 22:55:17.75,DOL5,1\n2025-05-13 22:55:17.96,DOL7,1",
      #     timestamp: "2025-05-13T22:55:18Z",
      #     subject: "..."
      #   }
      def create
        plc = find_plc
        if !plc
          render json: { error: 'PLC not found for the given email' }, status: :not_found
          return
        end

        data_points = parse_data_points(params[:data])
        if data_points.empty?
          render json: { error: 'No valid data points in payload' }, status: :unprocessable_entity
          return
        end

        results = process_data_points(plc, data_points)

        status = results[:errors].any? ? :multi_status : :ok
        render json: {
          processed: results[:processed],
          skipped: results[:skipped],
          errors: results[:errors]
        }, status: status
      end

      private
        def find_plc
          email = params[:from_email].to_s.strip
          if email.blank?
            return nil
          end

          Plc.includes(
            plc_version: :register_templates,
            measurement_points: :register_template
          ).find_by(username: email)
        end

        def parse_data_points(raw_data)
          if raw_data.blank?
            return []
          end

          raw_data.to_s.lines.filter_map do |line|
            line = line.strip
            if line.blank?
              next
            end

            parts = line.split(',', 3)
            if parts.length != 3
              next
            end

            timestamp_str, label, raw_value = parts
            timestamp = parse_timestamp(timestamp_str.strip, label.strip)
            if !timestamp
              next
            end

            {
              timestamp: timestamp,
              label: label.strip,
              raw_value: raw_value.strip
            }
          end
        end

        def parse_timestamp(timestamp_str, label)
          begin
            # Data comes in local time of the site.
            # We parse as-is and let the caller handle timezone if needed.
            Time.parse(timestamp_str)
          rescue ArgumentError, TypeError => e
            Rails.logger.warn("[PlcData] Invalid timestamp '#{timestamp_str}' for label '#{label}': #{e.message}")
            nil
          end
        end

        def process_data_points(plc, data_points)
          # Build lookup caches from preloaded data
          register_templates_by_label = plc.plc_version.register_templates.index_by(&:label)
          measurement_points_by_register_id = plc.measurement_points.index_by(&:register_template_id)

          results = { processed: 0, skipped: 0, errors: [] }
          raw_values_to_insert = []
          mp_updates = {} # measurement_point_id => { value:, timestamp: } (keep latest)

          data_points.each do |dp|
            register_template = register_templates_by_label[dp[:label]]
            if !register_template
              results[:skipped] += 1
              results[:errors] << { label: dp[:label], error: 'Unknown register label' }
              next
            end

            measurement_point = measurement_points_by_register_id[register_template.id]
            if !measurement_point
              results[:skipped] += 1
              results[:errors] << { label: dp[:label], error: 'No measurement point for register' }
              next
            end

            numeric_value = parse_numeric_value(dp[:raw_value])
            if !numeric_value
              results[:skipped] += 1
              results[:errors] << { label: dp[:label], error: "Invalid numeric value: #{dp[:raw_value]}" }
              next
            end

            factor = measurement_point.effective_factor || 1
            offset = measurement_point.effective_offset || 0
            scaled_value = (numeric_value * factor) + offset

            raw_values_to_insert << {
              measurement_point_id: measurement_point.id,
              value: numeric_value,
              scaled_value: scaled_value,
              sample_time: dp[:timestamp],
              created_at: Time.current
            }

            # Track latest value per measurement point for last_decoded_value update
            existing = mp_updates[measurement_point.id]
            if existing.nil? || dp[:timestamp] > existing[:timestamp]
              mp_updates[measurement_point.id] = {
                value: dp[:raw_value],
                scaled_value: scaled_value,
                timestamp: dp[:timestamp]
              }
            end

            results[:processed] += 1
          end

          persist_data!(raw_values_to_insert, mp_updates)

          results
        end

        def parse_numeric_value(value_str)
          begin
            Float(value_str)
          rescue ArgumentError, TypeError
            nil
          end
        end

        def persist_data!(raw_values_to_insert, mp_updates)
          if raw_values_to_insert.empty?
            return
          end

          ApplicationRecord.transaction do
            # Bulk insert raw values
            RawValue.insert_all(raw_values_to_insert)

            # Update last_decoded_value for each affected measurement point
            now = Time.current
            mp_updates.each do |mp_id, data|
              MeasurementPoint.where(id: mp_id).update_all(
                last_decoded_value: data[:value],
                last_decoded_value_at: data[:timestamp],
                updated_at: now
              )
            end
          end

          # TODO: Enqueue threshold check job for affected measurement points
          # ThresholdCheckJob.perform_async(mp_updates.keys)
        end
    end
  end
end

module Api
  module V1
    class PlcDataController < Api::V1::BaseController
      # POST /api/v1/plc_data
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
            :site,
            plc_version: :register_templates,
            measurement_points: :register_template
          ).find_by(username: email)
        end

        def parse_data_points(data)
          case data[:format]
          when 'csv'
            parse_csv_data_points(data[:data])
          else
            parse_raw_text_data_points(data)
          end
        end

        def parse_csv_data_points(raw_data)
          if raw_data.blank?
            return []
          end

          raw_data.filter_map do |row|
            if row.length != 3
              next
            end

            sample_time, label, raw_value = row
            {
              sample_time: sample_time.strip,
              label: label.strip,
              raw_value: raw_value.strip
            }
          end
        end

        def parse_raw_text_data_points(raw_data)
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

            sample_time, label, raw_value = parts
            {
              sample_time: sample_time.strip,
              label: label.strip,
              raw_value: raw_value.strip
            }
          end
        end

        def process_data_points(plc, data_points)
          site_tz = plc.site&.time_zone_object || ActiveSupport::TimeZone['UTC']

          register_templates_by_label = plc.plc_version.register_templates.index_by(&:label)
          measurement_points_by_register_id = plc.measurement_points.index_by(&:register_template_id)

          results = { processed: 0, skipped: 0, errors: [] }
          raw_values_to_insert = []
          mp_updates = {}

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

            utc_sample_time = site_tz.parse(dp[:sample_time]).utc

            factor = measurement_point.effective_factor || 1
            offset = measurement_point.effective_offset || 0
            scaled_value = (numeric_value * factor) + offset

            raw_values_to_insert << {
              measurement_point_id: measurement_point.id,
              value: numeric_value,
              scaled_value: scaled_value,
              sample_time: utc_sample_time,
              created_at: Time.current
            }

            existing = mp_updates[measurement_point.id]
            if existing.nil? || utc_sample_time > existing[:sample_time]
              mp_updates[measurement_point.id] = {
                value: dp[:raw_value],
                scaled_value: scaled_value,
                sample_time: utc_sample_time
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
            RawValue.insert_all(raw_values_to_insert)

            now = Time.current
            mp_updates.each do |mp_id, data|
              MeasurementPoint.where(id: mp_id).update_all(
                last_decoded_value: data[:value],
                last_decoded_value_at: data[:sample_time],
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

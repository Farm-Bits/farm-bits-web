class PlcReadJob
  include Sidekiq::Job
  queue_as :default
  sidekiq_options retry: 3

  def perform(plc_id)
    plc = Plc.includes(
      :gateway,
      site: :company,
      measurement_points: :register_template
    ).find_by(id: plc_id)

    if !plc || !plc.active? || !plc.gateway || !plc.gateway.active? || !plc.site || !plc.site.company.active?
      return
    end

    measurement_points = plc.measurement_points
      .where(active: true, data_collection_enabled: true)
      .includes(:register_template)
      .select { |mp| mp.needs_polling? }

    if measurement_points.empty?
      return
    end

    client = VpnManagerClient.new
    response = client.bulk_read_registers(
      plc,
      measurement_points
    )

    sample_time = Time.current
    if response[:sample_time].present?
      sample_time = Time.parse(response[:sample_time])
    end

    readings = []
    measurement_points.each do |mp|
      result = response[:results][mp.id]

      if !result
        next
      end

      if result[:status] == 'ok' && result[:values].present?
        decoded_value = mp.register_template.decode_data(result[:values])

        readings << {
          measurement_point: mp,
          value: decoded_value,
          sample_time: sample_time
        }
      else
        Rails.logger.warn(
          "Failed to read MP #{mp.id} (#{mp.name}) on PLC #{plc.id}: #{result[:error]}"
        )
      end
    end

    # Bulk persist all readings at once
    BulkRecordingService.new(readings).call
  rescue VpnManagerClient::ConnectionError => e
    Rails.logger.error("PLC #{plc_id} connection error: #{e.message}")
    raise
  rescue VpnManagerClient::NotFoundError => e
    Rails.logger.error("PLC #{plc_id} not found on VPN manager: #{e.message}")
    raise
  rescue => e
    Rails.logger.error("PLC #{plc_id} polling error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
  end
end

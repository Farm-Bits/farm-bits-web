class PlcReadService
  def initialize(plc, measurement_points)
    @plc = plc
    @measurement_points = measurement_points
  end

  def call
    if @measurement_points.blank?
      return false
    end

    if !@plc&.operational? || !@plc.gateway
      return false
    end

    client = VpnManagerClient.new
    response = client.bulk_read_registers(@plc, @measurement_points)

    sample_time = Time.current
    if response[:sample_time].present?
      sample_time = Time.parse(response[:sample_time])
    end

    readings = []
    @measurement_points.each do |mp|
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
          "PlcReadService: failed to read MP #{mp.id} (#{mp.name}) on PLC #{@plc.id}: #{result[:error]}"
        )
      end
    end

    BulkRecordingService.new(readings).call

    true
  end
end

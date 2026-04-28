# On-demand refresh of all user-visible MeasurementPoints belonging to a
# given source (Plc or ModbusDevice). Used for:
#
#   - Initial read after activation (Plc#enqueue_initial_read,
#     ModbusDevice#enqueue_initial_read)
#   - User-triggered "refresh values" from the UI
#
# Bypasses the needs_polling? filter - this job exists to force a read
# regardless of polling schedule. Reads only user-visible registers
# (skips diagnostic/internal).
#
# Usage:
#   ModbusRefreshJob.perform_async('Plc', plc_id)
#   ModbusRefreshJob.perform_async('ModbusDevice', modbus_device_id)
#   ModbusRefreshJob.perform_async('Plc', plc_id, categories: %w[data])
#
class ModbusRefreshJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: 3

  ALLOWED_SOURCES = %w[Plc ModbusDevice].freeze

  def perform(source_type, source_id, options = {})
    if !ALLOWED_SOURCES.include?(source_type)
      Rails.logger.error("ModbusRefreshJob: invalid source_type #{source_type.inspect}")
      return
    end

    mps = source_measurement_points(source_type, source_id, options)
    if mps.empty?
      return
    end

    ModbusReadEnqueuer.enqueue(mps)
  rescue VpnManagerClient::ConnectionError => e
    Rails.logger.error("ModbusRefreshJob #{source_type} #{source_id} connection error: #{e.message}")
    raise
  rescue VpnManagerClient::NotFoundError => e
    Rails.logger.error("ModbusRefreshJob #{source_type} #{source_id} not found: #{e.message}")
    raise
  rescue => e
    Rails.logger.error("ModbusRefreshJob #{source_type} #{source_id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
    Bugsnag.notify(e) do |report|
      report.severity = 'warning'
      report.add_metadata(:refresh, { source_type: source_type, source_id: source_id })
    end
  end

  private

  def source_measurement_points(source_type, source_id, options)
    scope = MeasurementPoint
      .user_visible
      .where(source_type.underscore + '_id' => source_id)
      .includes(*MeasurementPoint::READ_COORDINATES_INCLUDES)

    if options['categories'].present? || options[:categories].present?
      categories = options['categories'] || options[:categories]
      scope = scope.joins(:register_template)
                   .where(register_templates: { category: categories })
    end

    scope.to_a
  end
end

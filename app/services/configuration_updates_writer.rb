# Validates and writes a batch of MeasurementPoint configuration values
# in a single ModbusWriteService bulk_write. Used by:
#
#   - MeasurementPointsController#update          (with an anchor MP whose
#                                                  siblings define the allowed set)
#   - MeasurementPointsController#bulk_write      (with no anchor; allowed set
#                                                  is the union of MPs named in
#                                                  the payload, gated by policy)
#
# Raises one of the canonical errors below. Caller is responsible for
# rendering the failure (Rails `errors.add` for the in-line update flow,
# JSON for bulk_write).
#
class ConfigurationUpdatesWriter
  class Error            < StandardError; end
  class ValidationError  < Error; end
  class ConnectionError  < Error; end
  class WriteError       < Error; end

  WRITABLE_CONFIG_CATEGORIES = %w[
    interface_configuration
    operation_mode_configuration
    configuration
    program_configuration
  ].freeze

  # @param allowed_points [Hash{Integer => MeasurementPoint}]
  #   Map of allowed measurement_point_id => MP, pre-loaded with
  #   register_template, plc, gateway. Anything not in this map is rejected.
  # @param updates [Array<Hash>] each { measurement_point_id:, value: }
  # @param context [ModbusWriteContext]
  def initialize(allowed_points:, updates:, context:)
    @allowed_points = allowed_points
    @updates        = updates
    @context        = context
  end

  def call
    if @updates.empty?
      return
    end

    validate_ids_allowed!
    validate_register_groups!
    bulk_write!
  end

  private
    def validate_ids_allowed!
      @updates.each do |update|
        if !@allowed_points.key?(update[:measurement_point_id].to_i)
          raise ValidationError,
            "Invalid configuration: #{update[:measurement_point_id]}"
        end
      end
    end

    def validate_register_groups!
      pending_values = @updates.each_with_object({}) do |update, hash|
        mp = @allowed_points[update[:measurement_point_id].to_i]
        hash[mp.register_template_id] = update[:value]
      end

      validator = Validators::RegisterGroupValidator.new(@allowed_points.values, pending_values)
      if !validator.valid?
        raise ValidationError, validator.errors.join('; ')
      end
    end

    def bulk_write!
      payload = @updates.map do |update|
        {
          measurement_point: @allowed_points[update[:measurement_point_id].to_i],
          value:             update[:value]
        }
      end

      ModbusWriteService.new.bulk_write!(payload, context: @context)
    rescue ModbusWriteService::ValidationError => e
      raise ValidationError, e.message
    rescue ModbusWriteService::ConnectionError => e
      raise ConnectionError, e.message
    rescue ModbusWriteService::WriteError => e
      raise WriteError, e.message
    end
end

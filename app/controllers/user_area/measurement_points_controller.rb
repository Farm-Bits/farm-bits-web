class UserArea::MeasurementPointsController < UserArea::ApplicationController
  before_action :set_measurement_point, only: [:update, :write]

  def update
    authorize @measurement_point, :update?

    ActiveRecord::Base.transaction do
      if !@measurement_point.update(measurement_point_params)
        raise ActiveRecord::Rollback
      end

      if params[:configuration_updates].present?
        process_configuration_updates!
      end
    end

    if @measurement_point.errors.empty?
      render json: {
        measurement_point: MeasurementPointSerializer.render_as_json(@measurement_point),
        sibling_measurement_points: MeasurementPointSerializer.render_as_json(sibling_measurement_points)
      }, status: :ok
    else
      render json: { error: @measurement_point.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def write
    authorize @measurement_point, :write?

    begin
      context = PlcWriteContext.user_action(current_user)
      service = PlcWriteService.new(@measurement_point)
      service.write!(params[:value], context: context)

      render json: MeasurementPointSerializer.render_as_json(@measurement_point.reload), status: :ok
    rescue PlcWriteService::ValidationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue PlcWriteService::ConnectionError => e
      render json: { error: e.message }, status: :service_unavailable
    rescue PlcWriteService::WriteError => e
      Rails.logger.error "MeasurementPoint write error: #{e.message}"
      render json: { error: 'Failed to write value to PLC' }, status: :internal_server_error
    end
  end

  private
    def set_measurement_point
      @measurement_point = policy_scope(MeasurementPoint)
        .includes(:measurement_subtype, :register_template, :segment, plc: [:gateway])
        .find(params[:id])
    end

    def measurement_point_params
      params.require(:measurement_point).permit(
        :name,
        :description,
        :unit_override,
        :chart_type_override,
        :color_override,
        # :data_collection_enabled,
        # :polling_interval_seconds,
        :factor_override,
        :offset_override,
        :alarm_low,
        :alarm_high,
        :warning_low,
        :warning_high,
        :active,
        :measurement_subtype_id,
        :segment_id
      )
    end

    def configuration_updates_params
      if !params[:configuration_updates].is_a?(Array)
        return []
      end

      params[:configuration_updates].map do |update|
        update.permit(:measurement_point_id, :value)
      end
    end

    def process_configuration_updates!
      updates = configuration_updates_params
      if updates.empty?
        return
      end

      # Load allowed config points for this interface
      allowed_config_points = @measurement_point.configuration_measurement_points
        .joins(:register_template)
        .where(register_templates: { user_visibility: 'visible' })
        .includes(:register_template, plc: [:gateway])
        .index_by(&:id)

      # Validate all measurement point IDs are allowed
      updates.each do |update|
        if !allowed_config_points.key?(update[:measurement_point_id].to_i)
          @measurement_point.errors.add(:base, "Invalid configuration: #{update[:measurement_point_id]}")
          raise ActiveRecord::Rollback
        end
      end

      # Build pending values for group validation
      pending_values = updates.each_with_object({}) do |update, hash|
        config_point = allowed_config_points[update[:measurement_point_id].to_i]
        hash[config_point.register_template_id] = update[:value]
      end

      validator = RegisterGroupValidator.new(allowed_config_points.values, pending_values)
      if !validator.valid?
        @measurement_point.errors.add(:base, validator.errors.join('; '))
        raise ActiveRecord::Rollback
      end

      # Build payload for the write service
      config_points_with_values = updates.map do |update|
        {
          measurement_point: allowed_config_points[update[:measurement_point_id].to_i],
          value: update[:value]
        }
      end

      context = PlcWriteContext.user_action(current_user)
      service = PlcWriteService.new(@measurement_point)
      service.bulk_write!(config_points_with_values, context: context)
    rescue PlcWriteService::ValidationError => e
      @measurement_point.errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    rescue PlcWriteService::ConnectionError => e
      @measurement_point.errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    rescue PlcWriteService::WriteError => e
      Rails.logger.error "Configuration write error: #{e.message}"
      @measurement_point.errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    def sibling_measurement_points
      interface_ids = @measurement_point.register_template
          &.interface_register_mappings
          &.pluck(:interface_id)
      if !interface_ids.present?
        return []
      end

      MeasurementPoint
        .joins(register_template: :interface_register_mappings)
        .where(interface_register_mappings: { interface_id: interface_ids })
        .where.not(id: @measurement_point.id)
        .distinct
    end
end

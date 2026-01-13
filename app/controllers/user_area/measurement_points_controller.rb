class UserArea::MeasurementPointsController < UserArea::ApplicationController
  before_action :set_measurement_point, only: [:update, :write]

  def update
    authorize @measurement_point, :update?

    if @measurement_point.update(measurement_point_params)
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

    if @measurement_point.register_template.read_only?
      render json: { error: 'This register is read-only' }, status: :unprocessable_entity
      return
    end

    begin
      @measurement_point.write_value!(params[:value])
      render json: MeasurementPointSerializer.render_as_json(@measurement_point), status: :ok
    rescue MeasurementPoint::WriteValidationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "MeasurementPoint write error: #{e.message}"
      render json: { error: 'Failed to write value to PLC' }, status: :internal_server_error
    end
  end

  private
    def set_measurement_point
      @measurement_point = policy_scope(MeasurementPoint)
        .includes(:measurement_subtype, :register_template, :segment, :plc)
        .find(params[:id])
    end

    def measurement_point_params
      params.require(:measurement_point).permit(
        :name,
        :description,
        :unit_override,
        :chart_type_override,
        :color_override,
        :data_collection_enabled,
        :polling_interval_seconds,
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

    def sibling_measurement_points
      interface_ids = @measurement_point.register_template
          &.interface_register_mappings
          &.pluck(:interface_id)

      if interface_ids.present?
        MeasurementPoint
          .joins(register_template: :interface_register_mappings)
          .where(interface_register_mappings: { interface_id: interface_ids })
          .where.not(id: @measurement_point.id)
          .distinct
      else
        []
      end
    end
end

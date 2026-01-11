class UserArea::MeasurementPointsController < UserArea::ApplicationController
  before_action :set_measurement_point, only: [:update, :write]

  def update
    authorize @measurement_point, :update?

    if @measurement_point.update(measurement_point_params)
      render json: MeasurementPointSerializer.render(@measurement_point), status: :ok
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
      render json: MeasurementPointSerializer.render(@measurement_point), status: :ok
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
end

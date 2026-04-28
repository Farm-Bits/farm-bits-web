class UserArea::PlcsController < UserArea::ApplicationController
  before_action :set_plc, only: [:show, :update, :refresh_interfaces]

  def show
    authorize @plc, :show?

    data = {
      plc: PlcSerializer.render_as_json(@plc, view: :with_interfaces),
      measurementSubtypes: MeasurementSubtypeSerializer.render_as_json(measurement_subtypes)
    }

    respond_to do |format|
      format.html { render inertia: 'UserArea/Plcs/show', props: data }
      format.json { render json: data, status: :ok }
    end
  end

  def update
    authorize @plc, :update?

    if @plc.update(plc_params)
      set_plc
      render json: PlcSerializer.render_as_json(@plc, view: :with_interfaces), status: :ok
    else
      render json: { error: @plc.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def refresh_interfaces
    authorize @plc, :update?

    ModbusRefreshJob.perform_async(
      'Plc',
      @plc.id,
      'categories' => MeasurementSubtype::DATA_CATEGORIES
    )

    render json: { status: 'refresh_started' }, status: :accepted
  end

  private
    def plc_params
      params.require(:plc).permit(:name)
    end

    def set_plc
      @plc = policy_scope(Plc)
        .includes(:model, modbus_firmware_version: { interfaces: { interface_register_mappings: :register_template } })
        .find(params[:id])

      visible_mps = @plc.measurement_points
        .user_visible
        .includes(:measurement_subtype, register_template: :interface_register_mappings)
        .to_a

      @plc.association(:measurement_points).target = visible_mps
      @plc.association(:measurement_points).loaded!
    end

    def measurement_subtypes
      MeasurementSubtype
        .includes(:measurement_type, :control_group)
        .joins(:measurement_type)
        .order('measurement_types.position, measurement_subtypes.position')
    end
end

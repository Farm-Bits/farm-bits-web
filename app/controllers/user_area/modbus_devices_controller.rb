class UserArea::ModbusDevicesController < UserArea::ApplicationController
  before_action :set_modbus_device, only: [:show, :update, :destroy]

  def show
    authorize @modbus_device, :show?

    register_mappings = @modbus_device.measurement_points
      .joins(:register_template)
      .where(register_templates: {
        category: MeasurementSubtype::DATA_CATEGORIES,
        user_visibility: 'visible'
      })
      .includes(:register_template, :measurement_subtype)
      .order('register_templates.position')
      .map do |mp|
        {
          register_template: RegisterTemplateSerializer.render_as_json(mp.register_template),
          measurement_point: MeasurementPointSerializer.render_as_json(mp),
          position:          mp.register_template.position
        }
      end

    data = {
      modbusDevice:        ModbusDeviceSerializer.render_as_json(@modbus_device),
      registerMappings:    register_mappings,
      segments:             SegmentSerializer.render_as_json(current_site.segments),
      measurementSubtypes: MeasurementSubtypeSerializer.render_as_json(
        MeasurementSubtype.includes(:measurement_type, :control_group).all
      )
    }

    respond_to do |format|
      format.html { render inertia: 'UserArea/ModbusDevices/show', props: data }
      format.json { render json: data, status: :ok }
    end
  end

  def create
    authorize ModbusDevice, :create?

    @modbus_device = ModbusDevice.new(modbus_device_params)
    @modbus_device.active = true unless params[:modbus_device].key?(:active)

    if @modbus_device.save
      render json: { id: @modbus_device.id, name: @modbus_device.name }, status: :created
    else
      render json: { error: @modbus_device.errors.full_messages.to_sentence },
             status: :unprocessable_entity
    end
  end

  def update
    authorize @modbus_device, :update?

    if @modbus_device.update(modbus_device_params)
      render json: { id: @modbus_device.id, name: @modbus_device.name }, status: :ok
    else
      render json: { error: @modbus_device.errors.full_messages.to_sentence },
             status: :unprocessable_entity
    end
  end

  def destroy
    authorize @modbus_device, :destroy?

    if @modbus_device.destroy
      render json: { id: @modbus_device.id }, status: :ok
    else
      render json: { error: @modbus_device.errors.full_messages.to_sentence },
             status: :unprocessable_entity
    end
  end

  def refresh_values
    authorize @modbus_device, :refresh_values?

    ModbusRefreshJob.perform_async(
      'modbus_device',
      @modbus_device.id
    )

    render json: { status: 'refresh_started' }, status: :accepted
  end

  private
    def set_modbus_device
      @modbus_device = policy_scope(ModbusDevice)
        .includes(
          :gateway,
          model: :manufacturer,
          plc: [:model],
          modbus_firmware_version: :register_templates,
          measurement_points: [:measurement_subtype, :register_template]
        )
        .find(params[:id])
    end

    def modbus_device_params
      params.require(:modbus_device).permit(
        :name, :slave_id, :private_ip,
        :model_id, :gateway_id, :plc_id, :active
      )
    end
end

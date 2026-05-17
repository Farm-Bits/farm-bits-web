class UserArea::ProgramsController < UserArea::ApplicationController
  def index
    authorize :program, :index?

    data = { sources: [] }

    respond_to do |format|
      format.html { render inertia: 'UserArea/Programs/index', props: data }
      format.json { render json: data, status: :ok }
    end
  end

  def show_plc
    plc = policy_scope(Plc)
      .includes(:gateway, :model, :modbus_firmware_version)
      .find(params[:id])

    authorize plc, :show?

    render_show(plc)
  end

  def show_modbus_device
    modbus_device = policy_scope(ModbusDevice)
      .includes(:gateway, :model, :modbus_firmware_version, plc: [:gateway])
      .find(params[:id])

    authorize modbus_device, :show?

    render_show(modbus_device)
  end

  private
    def render_show(source)
      data = {}

      if data[:programs].empty?
        if request.format.json?
          render json: { error: 'No programs are configured on this device' }, status: :not_found
        else
          redirect_to user_programs_path, alert: 'No programs are configured on this device'
        end
        return
      end

      respond_to do |format|
        format.html { render inertia: 'UserArea/Programs/show', props: data }
        format.json { render json: data, status: :ok }
      end
    end
end

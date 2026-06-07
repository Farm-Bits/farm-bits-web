class UserArea::ProgramsController < UserArea::ApplicationController
  before_action :set_plc,           only: [:show_plc]
  before_action :set_modbus_device, only: [:show_modbus_device]

  def index
    authorize :program, :index?

    data = { sources: program_sources }

    respond_to do |format|
      format.html { render inertia: 'UserArea/Programs/index', props: data }
      format.json { render json: data, status: :ok }
    end
  end

  def show_plc
    render_programs(@plc)
  end

  def show_modbus_device
    render_programs(@modbus_device)
  end

  private
    def set_plc
      @plc = policy_scope(Plc)
        .includes(
          :model,
          :modbus_firmware_version,
          measurement_points: [:register_template, :measurement_subtype]
        )
        .find(params[:id])

      authorize @plc, :show?
    end

    def set_modbus_device
      @modbus_device = policy_scope(ModbusDevice)
        .includes(
          :model,
          :plc,
          :modbus_firmware_version,
          measurement_points: [:register_template, :measurement_subtype]
        )
        .find(params[:id])

      authorize @modbus_device, :show?
    end

    def render_programs(source)
      data = ProgramsBuilder.new(source).build
      if data.nil?
        render_no_programs
        return
      end

      respond_to do |format|
        format.html { render inertia: 'UserArea/Programs/show', props: data }
        format.json { render json: data, status: :ok }
      end
    end

    def render_no_programs
      respond_to do |format|
        format.html { redirect_to user_programs_path(site_id: current_site.id), alert: 'This device has no programs.' }
        format.json { render json: { error: 'This device has no programs' }, status: :not_found }
      end
    end

    # Program-capable sources in the current site: any Plc or ModbusDevice
    # whose resolved behavior declares programs.
    def program_sources
      candidates =
        policy_scope(Plc).includes(:model, :modbus_firmware_version).to_a +
        policy_scope(ModbusDevice).includes(:model, :plc, :modbus_firmware_version).to_a

      candidates
        .select { |source| ModbusBehaviors.for(source).programs? }
        .map { |source| program_source_row(source) }
        .sort_by { |row| [row[:active] ? 0 : 1, row[:name].to_s.downcase] }
    end

    def program_source_row(source)
      {
        kind:         source_kind(source),
        id:           source.id,
        name:         source.name,
        display_type: source.model&.display_type,
        firmware:     source.modbus_firmware_version&.name,
        host:         source.is_a?(ModbusDevice) ? source.plc&.name : nil,
        active:       source.active?,
        last_seen_at: source.last_seen_at&.iso8601
      }
    end

    def source_kind(source)
      case source
      when Plc          then 'plc'
      when ModbusDevice then 'modbus_device'
      end
    end
end

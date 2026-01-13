class UserArea::TerminalsController < UserArea::ApplicationController
  before_action :set_terminal, only: [:update, :destroy]

  def index
    authorize Terminal, :index?

    terminals = policy_scope(Terminal).where(active: true)
      .includes(:model, :plcs)
    data = {
      terminals: TerminalSerializer.render_as_json(terminals, view: :with_plcs),
      availableTerminals: available_terminals_for_activation,
      availablePlcs: available_plcs_for_activation
    }

    respond_to do |format|
      format.html { render inertia: 'UserArea/Terminals/index', props: data }
      format.json { render json: data, status: :ok }
    end
  end

  def update
    authorize @terminal, :update?

    if @terminal.update(terminal_params)
      render json: TerminalSerializer.render_as_json(@terminal, view: :with_plcs), status: :ok
    else
      render json: { error: @terminal.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @terminal, :destroy?

    if @terminal.update(active: false)
      render json: TerminalSerializer.render_as_json(@terminal), status: :ok
    else
      render json: { error: @terminal.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def terminal_params
      params.require(:terminal).permit(:name, :iccid, :phone_number, :active, plc_assignments: [:id, :name])
    end

    def set_terminal
      @terminal = policy_scope(Terminal).find(params[:id])
    end

    def available_terminals_for_activation
      policy_scope(Terminal).where(active: false).map do |t|
        {
          id: t.id,
          label: t.label,
          name: t.name,
          imei: t.imei,
          iccid: t.iccid,
          phone_number: t.phone_number,
          private_ip: t.private_ip
        }
      end
    end

    def available_plcs_for_activation
      policy_scope(Plc).where(terminal_id: nil, active: false).map do |p|
        {
          id: p.id,
          label: p.label,
          name: p.name,
          slave: p.slave,
          private_ip: p.private_ip,
          last_seen_at: p.last_seen_at,
          plc_version: {
            id: p.plc_version.id,
            name: p.plc_version.name,
            description: p.plc_version.description
          }
        }
      end
    end
end

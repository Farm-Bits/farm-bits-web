class UserArea::GatewaysController < UserArea::ApplicationController
  before_action :set_gateway, only: [:update, :destroy]

  def index
    authorize Gateway, :index?

    gateways = policy_scope(Gateway).where(active: true)
      .includes(:model, :plcs)
    data = {
      gateways: GatewaySerializer.render_as_json(gateways, view: :with_plcs),
      availableGateways: available_gateways_for_activation,
      availablePlcs: available_plcs_for_activation
    }

    respond_to do |format|
      format.html { render inertia: 'UserArea/Gateways/index', props: data }
      format.json { render json: data, status: :ok }
    end
  end

  def update
    authorize @gateway, :update?

    if @gateway.update(gateway_params)
      render json: GatewaySerializer.render_as_json(@gateway, view: :with_plcs), status: :ok
    else
      render json: { error: @gateway.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @gateway, :destroy?

    if @gateway.update(active: false)
      render json: GatewaySerializer.render_as_json(@gateway), status: :ok
    else
      render json: { error: @gateway.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def gateway_params
      params.require(:gateway).permit(:name, :iccid, :phone_number, :active, plc_assignments: [:id, :name])
    end

    def set_gateway
      @gateway = policy_scope(Gateway).find(params[:id])
    end

    def available_gateways_for_activation
      policy_scope(Gateway).where(active: false).map do |t|
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
      policy_scope(Plc).where(gateway_id: nil, active: false).map do |p|
        {
          id: p.id,
          label: p.label,
          name: p.name,
          slave_id: p.slave_id,
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

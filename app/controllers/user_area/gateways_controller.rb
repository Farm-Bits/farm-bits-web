class UserArea::GatewaysController < UserArea::ApplicationController
  before_action :set_gateway, only: [:update]

  def update
    authorize @gateway, :update?

    if @gateway.update(gateway_params)
      render json: GatewaySerializer.render_as_json(@gateway, view: :with_plcs), status: :ok
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
end

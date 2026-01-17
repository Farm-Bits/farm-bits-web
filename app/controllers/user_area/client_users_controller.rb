class UserArea::ClientUsersController < UserArea::ApplicationController
  before_action :set_client_user, only: [:update, :destroy]

  def index
    authorize ClientUser, :index?

    client_users = policy_scope(ClientUser)
    render json: ClientUserSerializer.render_as_json(client_users), status: :ok
  end

  def update
    authorize @client_user, :update?

    if @client_user.update(client_user_params)
      render json: ClientUserSerializer.render_as_json(@client_user), status: :ok
    else
      render json: { error: @client_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @client_user, :destroy?

    begin
      @client_user.destroy!
      head :no_content
    rescue => e
      render json: { error: @client_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def client_user_params
      permitted = params.require(:client_user).permit(:user_id, :role)
      if permitted[:user_id].blank?
        raise ActionController::ParameterMissing, :user_id
      end
      permitted
    end

    def set_client_user
      @client_user = policy_scope(ClientUser).find_by(id: params[:id])
    end
end

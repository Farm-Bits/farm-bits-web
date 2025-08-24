class UserArea::UsersController < UserArea::ApplicationController
  before_action :ensure_can_manage_users!, only: [:update, :destroy]
  before_action :set_client_user, only: [:update, :destroy]

  def index
    users = User.with_client_context(current_client)
    render json: UserSerializer.render(users, view: :client_user)
  end

  def update
    if @client_user.update(client_user_params)
      user = @client_user.user.with_client_context(current_client)
      render json: UserSerializer.render(user, view: :client_user)
    else
      render json: { error: @client_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    if @client_user.update(active: false)
      head :no_content
    else
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
      @client_user = current_client.client_users.find_by(user_id: client_user_params[:user_id])
    end
end

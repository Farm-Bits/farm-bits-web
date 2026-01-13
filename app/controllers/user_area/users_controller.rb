class UserArea::UsersController < UserArea::ApplicationController
  before_action :set_user, only: [:update, :destroy]
  before_action :set_client_user, only: [:update, :destroy]

  def index
    authorize User, :index?

    users = policy_scope(User)
    render json: UserSerializer.render_as_json(users, view: :client_user, current_client: current_client), status: :ok
  end

  def update
    authorize @user, :update?

    if @client_user.update(client_user_params)
      render json: UserSerializer.render_as_json(@user, view: :client_user, current_client: current_client), status: :ok
    else
      render json: { error: @client_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user, :destroy?

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

    def set_user
      @user = policy_scope(User).find(params[:id])
    end

    def set_client_user
      @client_user = current_client.client_users.find_by(user: @user)
    end
end

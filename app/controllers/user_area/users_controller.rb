class UserArea::UsersController < UserArea::ApplicationController

  def index
    users = User.with_client_context(current_client)
    render json: UserSerializer.render(users, view: :client_user)
  end
end

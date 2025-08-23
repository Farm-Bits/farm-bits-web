class UserArea::RolesController < UserArea::ApplicationController
  before_action :ensure_can_manage_users!

  def index
    render json: RoleManageable.roles_array
  end

  private
    def ensure_can_manage_users!
      if !current_client.role_for(current_user).can_manage_users?
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
end

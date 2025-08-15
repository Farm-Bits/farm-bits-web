class AdminArea::ApplicationController < ApplicationController
  before_action :authenticate_admin_user!
  inertia_share do
    {
      userScope: 'admin_users',
      user: current_admin_user
    }
  end
end

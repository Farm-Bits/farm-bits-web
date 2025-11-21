class DashboardPolicy < ApplicationPolicy
  maps_to_controller 'user_area/dashboard', actions: {
    show: :show?
  }

  def show?
    true
  end
end

class DashboardPolicy < ApplicationPolicy
  def show?
    active_context?
  end
end

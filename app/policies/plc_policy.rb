class PlcPolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    admin? || site_admin?
  end

  def refresh_interfaces?
    admin? || site_admin? || manager?
  end

  class Scope < Scope
    def resolve
      scope.where(site: current_site)
    end
  end
end

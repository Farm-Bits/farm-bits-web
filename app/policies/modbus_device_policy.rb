class ModbusDevicePolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    admin? || site_admin?
  end

  def update?
    admin? || site_admin?
  end

  def destroy?
    admin? || site_admin?
  end

  def refresh_values?
    admin? || site_admin? || manager?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(site: current_site)
    end
  end
end

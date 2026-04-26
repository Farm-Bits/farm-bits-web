class ModbusDevicePolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    admin? || site_admin?
  end

  class Scope < Scope
    def resolve
      scope.where(site: current_site)
    end
  end
end

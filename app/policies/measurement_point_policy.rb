class MeasurementPointPolicy < ApplicationPolicy
  def update?
    admin? || site_admin?
  end

  def write?
    admin? || site_admin? || manager?
  end

  class Scope < Scope
    def resolve
      scope.where(site: current_site)
    end
  end
end

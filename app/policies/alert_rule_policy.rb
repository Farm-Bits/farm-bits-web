class AlertRulePolicy < ApplicationPolicy
  def create?
    admin? || site_admin?
  end

  def update?
    admin? || site_admin?
  end

  def destroy?
    admin? || site_admin?
  end

  class Scope < Scope
    def resolve
      scope.joins(measurement_point: :site).where(sites: { id: current_site })
    end
  end
end

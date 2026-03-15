class MeasurementPointPolicy < ApplicationPolicy
  def update?
    admin? || site_admin?
  end

  def write?
    admin? || site_admin? || manager?
  end

  class Scope < Scope
    def resolve
      scope.joins(:register_template)
        .where(site: current_site)
        .where.not(register_templates: { user_visibility: 'hidden' })
    end
  end
end

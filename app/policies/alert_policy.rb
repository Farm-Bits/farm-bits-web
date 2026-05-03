class AlertPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(site_id: current_site.id)
    end
  end
end

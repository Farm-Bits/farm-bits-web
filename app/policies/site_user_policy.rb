class SiteUserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(site: current_site)
    end
  end
end

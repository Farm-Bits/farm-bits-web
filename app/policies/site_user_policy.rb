class SiteUserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if !active_context?
        return scope.none
      end

      scope.where(site: current_site)
    end
  end
end

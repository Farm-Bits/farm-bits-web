class MeasurementPointPolicy < ApplicationPolicy
  def update?
    super && current_client_user&.admin?
  end

  def write?
    super && [
      Roleable::ROLE_IDS[:admin], Roleable::ROLE_IDS[:site_admin], Roleable::ROLE_IDS[:manager]
    ].include?(current_client_user&.role)
  end

  class Scope < Scope
    def resolve
      if !active_context?
        return scope.none
      end

      scope.where(site: current_site)
    end
  end
end

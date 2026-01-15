class SegmentPolicy < ApplicationPolicy
  def index?
    super
  end

  def create?
    super && current_client_user&.admin?
  end

  def update?
    super && current_client_user&.admin?
  end

  def destroy?
    super && current_client_user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      segments = scope.where(client: current_client, site: current_site, active: true)
      case current_client_user.role
      when 'admin'
        segments
      when 'manager', 'viewer'
        site_ids = policy_scope!(Site).pluck(:id)
        segments.where(site_id: site_ids)
      else
        scope.none
      end
    end
  end
end

class SitePolicy < ApplicationPolicy
  def index?
    super
  end

  def create?
    super && current_client_user&.admin?
  end

  def update?
    case current_client_user&.role
    when 'admin'
      super
    when 'manager'
      super && user_assigned_to_site?
    else
      false
    end
  end

  def destroy?
    super && current_client_user&.admin?
  end

  private
    def user_assigned_to_site?
      current_user.site_users.exists?(site: record, active: true)
    end

  class Scope < ApplicationPolicy::Scope
    def resolve
      sites = scope.where(client: current_client, active: true)
      case current_client_user.role
      when 'admin'
        sites
      when 'manager', 'viewer'
        sites.joins(:site_users)
          .where(site_users: { user: current_user, active: true })
          .distinct
      else
        scope.none
      end
    end
  end
end

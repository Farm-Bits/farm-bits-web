class SitePolicy < ApplicationPolicy
  maps_to_controller 'user_area/site', actions: {
    create: :create?,
    update: :update?,
    destroy: :destroy?
  }

  def index?
    user.present? && (current_client.present? || context&.dig(:client).present?)
  end

  def create?
    client_user_for_record&.admin? && belongs_to_accessible_client?
  end

  def update?
    case client_user_for_record&.role
    when 'admin'
      belongs_to_accessible_client? && not_changing_client?
    when 'manager'
      belongs_to_accessible_client? && user_assigned_to_site? && not_changing_client?
    else
      false
    end
  end

  def destroy?
    client_user_for_record&.admin? && belongs_to_accessible_client?
  end

  private
    def client_user_for_record
      target_client = record&.client || context&.dig(:client) || current_client
      if !target_client
        return nil
      end

      user.client_user_for(target_client)
    end

    def client_user
      client_user_for_record
    end

    def belongs_to_accessible_client?
      if record.nil?
        return true
      end

      if context && context[:client]
        return true
      end

      if !record.client
        return false
      end

      user.client_users.exists?(client: record.client, active: true)
    end

    def not_changing_client?
      if !record.respond_to?(:client_id_changed?)
        return true
      end

      if !record.client_id_changed?
        return true
      end

      new_client = Client.find_by(id: record.client_id)
      if !new_client
        return false
      end

      user.client_users.exists?(client: new_client, active: true)
    end

    def user_assigned_to_site?
      if !user || !record
        return false
      end

      user.site_users.exists?(site: record, active: true)
    end

  class Scope < ApplicationPolicy::Scope
    def initialize(user, scope, current_client: nil)
      super(user, scope)
      @current_client = current_client
    end

    def resolve
      if !user || !current_client
        return scope.none
      end

      client_user = user.client_user_for(current_client)
      if !client_user || !client_user.active?
        return scope.none
      end

      sites = scope.where(client: current_client, active: true)

      case client_user.role
      when 'admin'
        sites
      when 'manager', 'viewer'
        sites.joins(:site_users)
          .where(site_users: { user: user, active: true })
          .distinct
      else
        scope.none
      end
    end

    private
      attr_reader :current_client
  end
end

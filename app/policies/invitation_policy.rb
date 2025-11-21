class InvitationPolicy < ApplicationPolicy
  maps_to_controller 'user_area/invitation', actions: {
    index: :index?,
    create: :create?,
    resend: :resend?,
    destroy: :destroy?
  }

  def index?
    client_user_for_record&.admin?
  end

  def create?
    client_user_for_record&.admin? && belongs_to_accessible_client?
  end

  def resend?
    client_user_for_record&.admin? && belongs_to_accessible_client?
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
      if !client_user || !client_user.active
        return scope.none
      end

      scope.where(client: current_client)
    end

    private
      attr_reader :current_client
  end
end

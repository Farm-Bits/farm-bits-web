class UserPolicy < ApplicationPolicy
  maps_to_controller 'user_area/my_account', actions: {
    show: :show?,
    update: :update?,
    destroy: :destroy?
  }

  maps_to_controller 'user_area/user', actions: {
    index: :index?,
    update: :update?,
    destroy: :destroy?
  }

  def index?
    client_user_for_record&.active?
  end

  def show?
    user_belongs_to_accessible_client?
  end

  def update?
    record == user
  end

  def destroy?
    record == user
  end

  private
    def client_user_for_record
      target_client = context&.dig(:client) || current_client
      if !target_client
        return nil
      end

      user.client_user_for(target_client)
    end

    def client_user
      client_user_for_record
    end

    def user_belongs_to_accessible_client?
      if record == user
        return true
      end

      if record.nil?
        return true
      end

      if context && context[:client]
        return true
      end

      target_client = context&.dig(:client) || current_client
      if !target_client
        return false
      end

      if !user.client_users.exists?(client: target_client, active: true)
        return false
      end

      record.client_users.exists?(client: target_client, active: true)
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

      if client_user.admin?
        scope.joins(:client_users)
          .where(client_users: { client: current_client, active: true })
          .where(active: true)
          .distinct
      else
        scope.where(id: user.id)
      end
    end

    private
      attr_reader :current_client
  end
end

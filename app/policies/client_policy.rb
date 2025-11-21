class ClientPolicy < ApplicationPolicy
  maps_to_controller 'user_area/client_setup', actions: {
    new: :new?,
    edit: :edit?,
    create: :create?,
    update: :update?,
    destroy: :destroy?
  }

  def new?
    user.present?
  end

  def edit?
    user_has_access_to_client?
  end

  def create?
    user.present? && creating_valid_client?
  end

  def update?
    client_user_for_record&.admin? && user_has_access_to_client?
  end

  def destroy?
    client_user_for_record&.admin? && user_has_access_to_client?
  end

  private
    def client_user_for_record
      target_client = record || current_client
      if !target_client
        return nil
      end

      user.client_user_for(target_client)
    end

    def client_user
      client_user_for_record
    end

    def user_has_access_to_client?
      if record.nil?
        return true
      end

      if !user || !record
        return false
      end

      user.client_users.exists?(client: record, active: true)
    end

    def creating_valid_client?
      if record.nil?
        return true
      end

      user_has_access_to_client?
    end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if !user
        return scope.none
      end

      scope.joins(:client_users)
        .where(client_users: { user: user, active: true })
        .where(active: true)
        .distinct
    end
  end
end

class ClientUserPolicy < ApplicationPolicy
  def index?
    super
  end

  def update?
    super && current_client_user&.admin?
  end

  def destroy?
    super && current_client_user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(client: current_client, active: true)
    end
  end
end

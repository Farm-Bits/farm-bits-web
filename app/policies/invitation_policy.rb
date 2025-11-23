class InvitationPolicy < ApplicationPolicy
  def index?
    super && current_client_user&.admin?
  end

  def create?
    super && current_client_user&.admin?
  end

  def resend?
    super && current_client_user&.admin?
  end

  def destroy?
    super && current_client_user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(client: current_client)
    end
  end
end

class TerminalPolicy < ApplicationPolicy
  def index?
    super
  end

  def update?
    super && current_client_user&.admin?
  end

  def destroy?
    super && current_client_user&.admin?
  end

  class Scope < Scope
    def resolve
      scope.where(client_id: current_client.id)
    end
  end
end

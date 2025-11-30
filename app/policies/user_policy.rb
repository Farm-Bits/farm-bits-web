class UserPolicy < ApplicationPolicy
  def index?
    super
  end

  def show?
    super && record.id == current_user.id
  end

  def update?
    super && record.id == current_user.id
  end

  def destroy?
    super && record.id == current_user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:client_users)
        .where(client_users: { client: current_client, active: true })
        .where(active: true)
        .distinct
    end
  end
end

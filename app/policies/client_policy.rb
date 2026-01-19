class ClientPolicy < ApplicationPolicy
  def create?
    true
  end

  def new?
    create?
  end

  def edit?
    admin? || site_admin? || manager?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:client_users)
        .where(client_users: { user: current_user })
        .where(active: true)
        .distinct
    end
  end
end

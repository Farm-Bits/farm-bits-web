class UserPolicy < ApplicationPolicy
  def show?
    record.id == current_user.id
  end

  def update?
    record.id == current_user.id
  end

  def destroy?
    record.id == current_user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      client_user_ids = policy_scope!(ClientUser)
        .pluck(:user_id)

      scope.where(id: client_user_ids)
        .where(active: true)
    end
  end
end

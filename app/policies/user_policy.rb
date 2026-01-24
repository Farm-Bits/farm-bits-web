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
      company_user_ids = policy_scope!(CompanyUser)
        .pluck(:user_id)

      scope.where(id: company_user_ids)
        .where(active: true)
    end
  end
end

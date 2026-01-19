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
      admin_user_ids = ClientUser
        .where(client: current_client, role: Roleable::ROLE_IDS[:admin])
        .pluck(:user_id)

      site_user_ids = SiteUser
        .where(site: current_site)
        .pluck(:user_id)

      visible_user_ids = (admin_user_ids + site_user_ids).uniq

      scope.where(id: visible_user_ids)
        .where(active: true)
        .distinct
    end
  end
end

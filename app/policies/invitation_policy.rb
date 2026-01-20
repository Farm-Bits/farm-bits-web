class InvitationPolicy < ApplicationPolicy
  def index?
    admin? || site_admin?
  end

  def create?
    admin? || site_admin?
  end

  # def update?
  #   admin? || site_admin?
  # end

  def resend?
    admin? || site_admin?
  end

  def destroy?
    admin? || site_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin?
        scope.where(client: current_client)
      else
        invitation_site_ids = policy_scope!(InvitationSite).select(:invitation_id)
        scope.where(client: current_client)
          .where(
            "invitations.role = ? OR invitations.id IN (?)",
            Roleable::ROLE_IDS[:admin],
            invitation_site_ids
          )
      end
    end
  end
end

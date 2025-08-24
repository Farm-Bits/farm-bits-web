class ClientUser < ApplicationRecord
  audited
  include RoleManageable

  belongs_to :client
  belongs_to :user

  validates :role, inclusion: { in: ROLES.keys }
  validates :client_id, uniqueness: { scope: :user_id }
  validates :user_id, uniqueness: { scope: :client_id }
  validate :cannot_deactivate_last_admin, if: :active_changed_to_false?

  private
    def active_changed_to_false?
      active_changed? && !active
    end

    def cannot_deactivate_last_admin
      highest_role = RoleManageable.highest_role
      if role != highest_role
        return
      end

      other_active_admins = client.client_users
        .where.not(id: id)
        .where(role: highest_role, active: true)
      if other_active_admins.empty?
        errors.add(:base, 'Cannot deactivate the last admin user')
      end
    end
end

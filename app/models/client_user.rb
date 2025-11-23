class ClientUser < ApplicationRecord
  audited
  include Roleable

  belongs_to :client
  belongs_to :user

  validates :client_id, uniqueness: { scope: :user_id }
  validates :user_id, uniqueness: { scope: :client_id }
  validates :role, presence: true
  validate :cannot_deactivate_last_admin, if: :active_changed_to_false?

  before_destroy :prevent_destroy_last_admin

  enum :role, Roleable::ROLE_IDS

  def last_admin_for_client?
    if !admin?
      return false
    end

    if !active && !active_was
      return false
    end

    other_active_admins = client.client_users
      .where.not(id: id)
      .where(role: Roleable::ROLE_IDS[:admin], active: true)

    other_active_admins.empty?
  end

  private
    def active_changed_to_false?
      active_changed? && !active
    end

    def cannot_deactivate_last_admin
      if last_admin_for_client?
        errors.add(:base, 'Cannot deactivate the last admin user')
      end
    end

    def prevent_destroy_last_admin
      if last_admin_for_client?
        errors.add(:base, 'Cannot delete the last admin user')
        throw(:abort)
      end
    end
end

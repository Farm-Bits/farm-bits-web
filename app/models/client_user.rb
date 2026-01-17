class ClientUser < ApplicationRecord
  audited
  include Roleable

  belongs_to :client
  belongs_to :user

  validates :client_id, uniqueness: { scope: :user_id }
  validates :user_id, uniqueness: { scope: :client_id }
  validates :role, presence: true

  before_destroy :prevent_destroy_last_admin
  after_destroy :destroy_user_if_orphaned

  enum :role, Roleable::ROLE_IDS

  def last_admin_for_client?
    if !admin?
      return false
    end

    other_admins = client.client_users
      .where.not(id: id)
      .where(role: Roleable::ROLE_IDS[:admin])

    other_admins.empty?
  end

  private
    def prevent_destroy_last_admin
      if last_admin_for_client? && !destroyed_by_association
        errors.add(:base, 'Cannot delete the last admin user')
        throw(:abort)
      end
    end

    def destroy_user_if_orphaned
      if user.client_users.count == 0
        user.destroy
      end
    end
end

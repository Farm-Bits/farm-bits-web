class SiteUser < ApplicationRecord
  audited
  include RoleManageable

  belongs_to :site
  belongs_to :user

  validates :site_id, uniqueness: { scope: :user_id }
  validates :user_id, uniqueness: { scope: :site_id }
  validates :role, inclusion: { in: ROLES.keys }
  validate :user_must_be_client_member

  private
    def user_must_be_client_member
      if !user.member_of?(site.client)
        errors.add(:user, 'must be a member of the client to access this site')
      end
    end
end

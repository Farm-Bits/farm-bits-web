class SiteUser < ApplicationRecord
  audited
  include Roleable

  belongs_to :site
  belongs_to :user

  validates :site_id, uniqueness: { scope: :user_id }
  validates :user_id, uniqueness: { scope: :site_id }
  validates :role, presence: true
  validate :user_must_be_client_member

  enum :role, Roleable::ROLES

  private
    def user_must_be_client_member
      if !user.member_of?(site.client)
        errors.add(:user, 'must be a member of the client to access this site')
      end
    end
end

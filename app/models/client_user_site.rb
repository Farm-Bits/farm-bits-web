class ClientUserSite < ApplicationRecord
  audited

  belongs_to :client_user
  belongs_to :site

  validates :client_user_id, uniqueness: { scope: :site_id }
  validates :site_id, uniqueness: { scope: :client_user_id }
  validate :site_belongs_to_client_user_client

  private
    def site_belongs_to_client_user_client
      if site.client_id != client_user.client_id
        errors.add(:site, 'must belong to the same client as the client_user')
      end
    end
end

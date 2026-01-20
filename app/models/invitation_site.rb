class InvitationSite < ApplicationRecord
  audited

  belongs_to :invitation
  belongs_to :site

  validates :site_id, uniqueness: { scope: :invitation_id }
  validates :invitation_id, uniqueness: { scope: :site_id }
  validate :site_belongs_to_invitation_client

  private
    def site_belongs_to_invitation_client
      if site.client_id != invitation.client_id
        errors.add(:site, 'must belong to the same client as the invitation')
      end
    end
end

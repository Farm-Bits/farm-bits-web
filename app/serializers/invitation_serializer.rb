class InvitationSerializer < Blueprinter::Base
  identifier :id

  fields :email, :role, :status

  field :visible_site_ids do |invitation, options|
    user_site_ids = get_invitation_site_ids(invitation)
    viewer_site_ids = get_viewer_site_ids(options[:context])

    user_site_ids & viewer_site_ids
  end

  field :total_sites_count do |invitation, options|
    get_invitation_site_ids(invitation).count
  end

  private
    def self.get_invitation_site_ids(invitation)
      invitation.invitation_sites.pluck(:site_id)
    end

    def self.get_viewer_site_ids(context)
      Pundit.policy_scope!(context, Site).pluck(:id)
    end
end

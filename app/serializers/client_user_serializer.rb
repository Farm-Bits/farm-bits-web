class ClientUserSerializer < Blueprinter::Base
  identifier :id

  fields :role

  field :user do |client_user|
    client_user.user.as_json(only: [:id, :name, :email])
  end

  field :visible_site_ids do |client_user, options|
    user_site_ids = get_client_user_site_ids(client_user)
    viewer_site_ids = get_viewer_site_ids(options[:context])

    user_site_ids & viewer_site_ids
  end

  field :total_sites_count do |client_user, options|
    get_client_user_site_ids(client_user).count
  end

  private
    def self.get_client_user_site_ids(client_user)
      client_user.client_user_sites.pluck(:site_id)
    end

    def self.get_viewer_site_ids(context)
      Pundit.policy_scope!(context, Site).pluck(:id)
    end
end

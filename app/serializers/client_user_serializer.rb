class ClientUserSerializer < Blueprinter::Base
  identifier :id

  fields :client_id, :user_id, :role

  field :user do |client_user|
    client_user.user.as_json(only: [:id, :name, :email])
  end

  field :site_ids do |client_user|
    client_user.user.site_users.pluck(:site_id)
  end

  field :visible_site_ids do |client_user, options|
    user_site_ids = get_user_site_ids(client_user, options)
    viewer_site_ids = get_viewer_site_ids(options[:context])

    user_site_ids & viewer_site_ids
  end

  field :total_sites_count do |client_user, options|
    get_user_site_ids(client_user, options).count
  end

  field :has_other_sites do |client_user, options|
    total = get_user_site_ids(client_user, options).count
    visible = (get_user_site_ids(client_user, options) & get_viewer_site_ids(options[:context])).count

    total > visible
  end

  private
    def self.get_user_site_ids(client_user, options)
      SiteUser.joins(:site)
        .where(user: client_user.user)
        .where(sites: { client: options[:context][:current_client] })
        .pluck(:site_id)
    end

    def self.get_viewer_site_ids(context)
      SitePolicy::Scope.new(context, Site).resolve.pluck(:id)
    end
end

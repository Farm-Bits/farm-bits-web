class CompanyUserSerializer < Blueprinter::Base
  identifier :id

  fields :role

  field :user do |company_user|
    company_user.user.as_json(only: [:id, :name, :email])
  end

  field :visible_site_ids do |company_user, options|
    user_site_ids = get_company_user_site_ids(company_user)
    viewer_site_ids = get_viewer_site_ids(options[:context])

    user_site_ids & viewer_site_ids
  end

  field :total_sites_count do |company_user, options|
    get_company_user_site_ids(company_user).count
  end

  private
    def self.get_company_user_site_ids(company_user)
      company_user.company_user_sites.pluck(:site_id)
    end

    def self.get_viewer_site_ids(context)
      Pundit.policy_scope!(context, Site).pluck(:id)
    end
end

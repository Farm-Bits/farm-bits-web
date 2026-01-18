class SiteUserSerializer < Blueprinter::Base
  identifier :id

  fields :site_id, :user_id

  field :user_name do |site_user|
    site_user.user.name
  end
end

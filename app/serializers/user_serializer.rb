class UserSerializer < Blueprinter::Base
  identifier :id

  fields :name, :email

  view :client_user do
    field(:role) do |user, options|
      user.role_for_current_client
    end

    field(:active) do |user, options|
      user.active_for_current_client?
    end
  end
end

class UserSerializer < Blueprinter::Base
  identifier :id

  fields :name, :email

  view :client_user do
    field(:role) do |user, options|
      current_client = options[:current_client]
      client_user = user.client_user_for(current_client)
      client_user&.role
    end

    field(:active) do |user, options|
      current_client = options[:current_client]
      client_user = user.client_user_for(current_client)
      client_user&.active?
    end
  end
end

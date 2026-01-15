class ClientUserSerializer < Blueprinter::Base
  identifier :id

  fields :client_id, :user_id, :role

  field :user do |client_user|
    client_user.user.as_json(only: [:id, :name, :email])
  end
end

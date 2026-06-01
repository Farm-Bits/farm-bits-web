class Api::Mobile::V1::UserSerializer < Blueprinter::Base
  identifier :id

  fields :name, :email
end

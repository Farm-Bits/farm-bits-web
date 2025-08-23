class InvitationSerializer < Blueprinter::Base
  identifier :id

  fields :email, :role, :status

  field(:expired) { |invitation| invitation.expired? }
end

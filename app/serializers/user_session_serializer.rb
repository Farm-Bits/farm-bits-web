class UserSessionSerializer < Blueprinter::Base
  identifier :id

  fields :transport, :client_name, :ip_address, :last_seen_at, :expires_at

  field :is_current_session do |session, options|
    options[:current_session_id] == session.id
  end

  field :remembered do |session|
    session.remember_token_digest.present?
  end
end

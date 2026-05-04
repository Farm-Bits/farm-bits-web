require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class UserSessionToken < Authenticatable
      # Run before :database_authenticatable so existing session-cookie
      # users authenticate without retrying credentials.
      def valid?
        if signing_in?
          return false
        end

        session_id_from_cookie.present? || remember_cookie_present?
      end

      def authenticate!
        session = locate_session
        if session.nil?
          return fail(:invalid_session)
        end

        if !session.fully_authorized?
          clear_cookies!
          return fail(:session_not_authorized)
        end

        authenticatable = session.authenticatable
        if authenticatable.nil? || (authenticatable.respond_to?(:active?) && !authenticatable.active?)
          clear_cookies!
          return fail(:authenticatable_inactive)
        end

        # Stash the session id in the Rails session cookie so subsequent
        # requests skip the bcrypt path on the remember cookie.
        request.session[session_cookie_key] = session.id
        request.env[user_session_env_key] = session

        success!(authenticatable)
      end

      private
        def signing_in?
          request.post? && request.path.match?(%r{\A/(?:users|admin_users)/sign_in\z})
        end

        def locate_session
          session_id = session_id_from_cookie
          if session_id.present?
            row = UserSession.active.find_by(id: session_id)
            if row.present? && row.authenticatable_type == scope_class_name
              return row
            end
          end

          locate_via_remember_cookie
        end

        def locate_via_remember_cookie
          cookie = remember_cookie_value
          if cookie.blank?
            return nil
          end

          session_id, plaintext_token = cookie
          if session_id.blank? || plaintext_token.blank?
            return nil
          end

          row = UserSession.active.find_by(id: session_id)
          if row.nil? || row.authenticatable_type != scope_class_name
            return nil
          end

          if !row.valid_remember_token?(plaintext_token)
            return nil
          end

          row
        end

        def session_id_from_cookie
          request.session[session_cookie_key]
        end

        def session_cookie_key
          "#{scope}_session_id"
        end

        def remember_cookie_present?
          request.cookie_jar.signed[remember_cookie_name].present?
        end

        def remember_cookie_value
          request.cookie_jar.signed[remember_cookie_name]
        end

        def remember_cookie_name
          "#{scope}_remember"
        end

        def scope_class_name
          scope.to_s.classify
        end

        def clear_cookies!
          request.session.delete(session_cookie_key)
          request.cookie_jar.delete(remember_cookie_name)
        end

        def user_session_env_key
          "user_session.current.#{scope}"
        end
    end
  end
end

Warden::Strategies.add(:user_session_token, Devise::Strategies::UserSessionToken)

Warden::Manager.after_set_user do |user, auth, opts|
  scope = opts[:scope]
  if !%i[user admin_user].include?(scope)
    next
  end

  env_key = "user_session.current.#{scope}"

  # Already wired up for this request (e.g., by SessionsController#create)
  if auth.env[env_key].present?
    next
  end

  # During sign-in itself, the controller is about to create the row and set
  # the session_id cookie. Don't enforce row existence yet — let the controller
  # finish its work.
  if signing_in?(auth.request)
    next
  end

  session_id = auth.request.session["#{scope}_session_id"]
  if session_id.nil?
    auth.logout(scope)
    next
  end

  user_session = UserSession.active.find_by(id: session_id)
  if user_session.nil? ||
    user_session.authenticatable_type != scope.to_s.classify ||
    user_session.authenticatable_id != user.id ||
    !user_session.fully_authorized?
    auth.logout(scope)
    next
  end

  auth.env[env_key] = user_session
end

def signing_in?(request)
  request.post? && request.path.match?(%r{\A/(?:users|admin_users)/sign_in\z})
end

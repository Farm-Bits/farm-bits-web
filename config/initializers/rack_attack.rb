class Rack::Attack
  ### Throttle: sign-in attempts per IP ###
  # 10 sign-in POSTs per minute per IP. Generous enough that a real user
  # mistyping their password 3 times won't hit it; tight enough to slow
  # a botnet. Both web and mobile sign-in count toward this.
  throttle('sign_in/ip', limit: 10, period: 1.minute) do |req|
    if sign_in_request?(req)
      req.ip
    end
  end

  ### Throttle: sign-in attempts per email ###
  # 5 sign-in POSTs per 20 minutes targeting the same email address.
  # Defends against credential-stuffing attacks that rotate IPs.
  throttle('sign_in/email', limit: 5, period: 20.minutes) do |req|
    if sign_in_request?(req)
      email = extract_email(req)
      email.present? ? email : nil
    end
  end

  ### Throttle: OTP verify attempts per session ###
  # 10 OTP submissions per 10 minutes per session_id. The model already
  # caps at OTP_MAX_ATTEMPTS=5 and revokes the session, but this prevents
  # creating fresh sessions just to burn attempts.
  throttle('otp_verify/session', limit: 10, period: 10.minutes) do |req|
    if otp_verify_request?(req)
      extract_session_id(req)
    end
  end

  ### Throttle: OTP resend per session ###
  # 3 resends per 10 minutes per session_id. Email flooding protection.
  throttle('otp_resend/session', limit: 3, period: 10.minutes) do |req|
    if otp_resend_request?(req)
      extract_session_id(req)
    end
  end

  ### Throttle: OTP requests per IP ###
  # Catches an attacker spinning up many sessions from one IP to flood
  # arbitrary email addresses with OTP messages.
  throttle('otp/ip', limit: 20, period: 10.minutes) do |req|
    if otp_verify_request?(req) || otp_resend_request?(req)
      req.ip
    end
  end

  ### Throttle: requests per IP ###
  # Throttle requests to 5 requests per second per IP address
  throttle('req/ip', limit: 5, period: 1.second) do |req|
    req.ip
  end

  ### Response when throttled ###
  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data'] || {}
    retry_after = match_data[:period].to_i

    headers = {
      'Content-Type' => 'application/json',
      'Retry-After'  => retry_after.to_s
    }

    body = {
      error: 'rate_limited',
      message: 'Too many attempts. Please try again later.',
      retry_after_seconds: retry_after
    }.to_json

    [429, headers, [body]]
  end

  class << self
    private
      def sign_in_request?(req)
        if !req.post?
          return false
        end

        path = req.path
        path == '/users/sign_in' ||
          path == '/admin_users/sign_in' ||
          path == '/api/mobile/v1/sign_in'
      end

      def otp_verify_request?(req)
        if !req.post?
          return false
        end

        path = req.path
        path == '/users/otp/verify' ||
          path == '/admin_users/otp/verify' ||
          path == '/api/mobile/v1/otp/verify'
      end

      def otp_resend_request?(req)
        if !req.post?
          return false
        end

        path = req.path
        path == '/users/otp/resend' ||
          path == '/admin_users/otp/resend' ||
          path == '/api/mobile/v1/otp/resend'
      end

      def extract_email(req)
        # Web form-encoded: params[:user][:email]
        # Mobile JSON: { email: "..." }
        body_email = nil

        if req.content_type&.start_with?('application/json')
          begin
            req.body.rewind
            parsed = JSON.parse(req.body.read)
            req.body.rewind
            body_email = parsed['email']
          rescue JSON::ParserError
            body_email = nil
          end
        else
          body_email = req.params.dig('user', 'email') || req.params['email']
        end

        body_email.to_s.downcase.strip.presence
      end

      def extract_session_id(req)
        if req.content_type&.start_with?('application/json')
          begin
            req.body.rewind
            parsed = JSON.parse(req.body.read)
            req.body.rewind
            return parsed['session_id'].to_s.presence
          rescue JSON::ParserError
            return nil
          end
        end

        req.params['session_id'].to_s.presence
      end
  end
end

ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn(
    "[Rack::Attack] throttled #{req.env['rack.attack.matched']} " \
    "ip=#{req.ip} path=#{req.path}"
  )
end

class MobileJwt
  ALGORITHM = 'HS256'.freeze

  class DecodeError < StandardError; end
  class ExpiredError < DecodeError; end

  def self.encode(payload)
    full_payload = payload.merge(exp: payload[:exp] || (Time.current + UserSession::MOBILE_EXPIRY).to_i)

    header  = base64url(JSON.dump({ alg: ALGORITHM, typ: 'JWT' }))
    body    = base64url(JSON.dump(full_payload))
    signing = "#{header}.#{body}"
    sig     = base64url(sign(signing))

    "#{signing}.#{sig}"
  end

  def self.decode(token)
    if token.blank?
      raise DecodeError, 'Token is blank'
    end

    parts = token.split('.')
    if parts.length != 3
      raise DecodeError, 'Malformed token'
    end

    header, body, sig = parts
    expected_sig = base64url(sign("#{header}.#{body}"))
    if !secure_compare(sig, expected_sig)
      raise DecodeError, 'Signature mismatch'
    end

    payload = JSON.parse(base64url_decode(body), symbolize_names: true)
    if payload[:exp].present? && payload[:exp] < Time.current.to_i
      raise ExpiredError, 'Token expired'
    end

    payload
  rescue JSON::ParserError
    raise DecodeError, 'Invalid JSON in token'
  end

  def self.secret
    Rails.application.credentials.dig(:mobile_jwt, :secret) ||
      raise('mobile_jwt.secret not configured in credentials')
  end

  def self.sign(data)
    OpenSSL::HMAC.digest('SHA256', secret, data)
  end

  def self.base64url(data)
    Base64.urlsafe_encode64(data, padding: false)
  end

  def self.base64url_decode(data)
    Base64.urlsafe_decode64(data)
  end

  def self.secure_compare(a, b)
    ActiveSupport::SecurityUtils.secure_compare(a, b)
  rescue ArgumentError
    false
  end
end

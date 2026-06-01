require 'bcrypt'

class UserSession < ApplicationRecord
  TRANSPORTS = %w[web mobile].freeze

  WEB_DEFAULT_EXPIRY    = 14.days
  WEB_REMEMBERED_EXPIRY = 90.days
  MOBILE_EXPIRY         = 60.days
  REMEMBER_TOKEN_LENGTH = 32
  LAST_SEEN_THROTTLE    = 1.minute
  OTP_CODE_LENGTH    = 6
  OTP_VALIDITY       = 10.minutes
  OTP_MAX_ATTEMPTS   = 5

  belongs_to :authenticatable, polymorphic: true
  belongs_to :current_company, class_name: 'Company', optional: true

  validates :transport, presence: true, inclusion: { in: TRANSPORTS }
  validates :last_seen_at, presence: true
  validates :expires_at, presence: true
  validates :jti, uniqueness: true, allow_nil: true
  validate :credentials_match_transport

  scope :active, -> {
    where(revoked_at: nil).where('expires_at > ?', Time.current)
  }
  scope :web,    -> { where(transport: 'web') }
  scope :mobile, -> { where(transport: 'mobile') }

  def web?
    transport == 'web'
  end

  def mobile?
    transport == 'mobile'
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    !revoked? && !expired?
  end

  def revoke!
    if revoked?
      return
    end

    update!(revoked_at: Time.current)
  end

  def self.create_web!(authenticatable:, request:, remembered: false)
    expiry = remembered ? WEB_REMEMBERED_EXPIRY : WEB_DEFAULT_EXPIRY

    session = new(
      authenticatable: authenticatable,
      transport:       'web',
      last_seen_at:    Time.current,
      expires_at:      expiry.from_now,
      user_agent:      truncate_user_agent(request.user_agent),
      ip_address:      request.remote_ip,
      client_name:     derive_client_name(request.user_agent)
    )

    remember_token = nil
    if remembered
      remember_token = SecureRandom.urlsafe_base64(REMEMBER_TOKEN_LENGTH)
      session.remember_token_digest = BCrypt::Password.create(
        remember_token, cost: Devise.stretches
      )
    end

    session.save!
    [session, remember_token]
  end

  def self.create_mobile!(authenticatable:, request:, current_company: nil, client_name: nil)
    jti = SecureRandom.uuid

    session = create!(
      authenticatable: authenticatable,
      transport:       'mobile',
      jti:             jti,
      current_company: current_company,
      last_seen_at:    Time.current,
      expires_at:      MOBILE_EXPIRY.from_now,
      user_agent:      truncate_user_agent(request.user_agent),
      ip_address:      request.remote_ip,
      client_name:     client_name.presence || derive_client_name(request.user_agent)
    )

    token = MobileJwt.encode(
      session_id: session.id,
      jti:        jti,
      user_id:    authenticatable.id,
      user_type:  authenticatable.class.name
    )

    [session, token]
  end

  def mobile_token
    if !mobile?
      return nil
    end

    MobileJwt.encode(
      session_id: id,
      jti:        jti,
      user_id:    authenticatable_id,
      user_type:  authenticatable_type
    )
  end

  def self.truncate_user_agent(user_agent)
    user_agent.to_s.first(500)
  end

  def self.derive_client_name(user_agent)
    ua = user_agent.to_s
    if ua.blank?
      return 'Unknown'
    end

    browser = case ua
              when /Edg\//      then 'Edge'
              when /Chrome\//   then 'Chrome'
              when /Firefox\//  then 'Firefox'
              when /Safari\//   then 'Safari'
              else 'Browser'
              end

    os = case ua
        when /Windows/         then 'Windows'
        when /Macintosh|Mac OS/ then 'macOS'
        when /iPhone/          then 'iPhone'
        when /iPad/            then 'iPad'
        when /Android/         then 'Android'
        when /Linux/           then 'Linux'
        end

    os ? "#{browser} on #{os}" : browser
  end

  def touch_seen!(ip:, user_agent:)
    if last_seen_at.present? && last_seen_at > LAST_SEEN_THROTTLE.ago
      return
    end

    update_columns(
      last_seen_at: Time.current,
      ip_address:   ip,
      user_agent:   self.class.truncate_user_agent(user_agent),
      updated_at:   Time.current
    )
  end

  def valid_remember_token?(plaintext_token)
    if remember_token_digest.blank? || plaintext_token.blank?
      return false
    end

    BCrypt::Password.new(remember_token_digest).is_password?(plaintext_token)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def issue_otp!
    begin
      if !active?
        return false
      end

      code = self.class.generate_otp_code
      update!(
        pending_otp_digest:     BCrypt::Password.create(code, cost: Devise.stretches),
        pending_otp_expires_at: OTP_VALIDITY.from_now,
        pending_otp_attempts:   0
      )

      UserSessionMailer.otp_code(self, code).deliver_now
      true
    rescue Net::SMTPError, IOError, Errno::ECONNREFUSED, Timeout::Error => e
      Rails.logger.warn("[OTP] delivery failed for session #{id}: #{e.message}")
      Bugsnag.notify(e) { |r| r.severity = 'warning'; r.add_metadata(:otp, { session_id: id }) }
      false
    end
  end

  def mark_otp_verified!
    update!(
      mfa_verified_at:        Time.current,
      pending_otp_digest:     nil,
      pending_otp_expires_at: nil,
      pending_otp_attempts:   0
    )
  end

  def verify_otp!(submitted_code)
    if pending_otp_digest.blank?
      return :no_pending_code
    end

    if pending_otp_expires_at.blank? || pending_otp_expires_at < Time.current
      return :expired
    end

    if pending_otp_attempts >= OTP_MAX_ATTEMPTS
      revoke!
      return :too_many_attempts
    end

    matches = begin
      BCrypt::Password.new(pending_otp_digest).is_password?(submitted_code.to_s)
    rescue BCrypt::Errors::InvalidHash
      false
    end

    if !matches
      increment!(:pending_otp_attempts)
      return :invalid
    end

    mark_otp_verified!
    :ok
  end

  def self.generate_otp_code
    # 6-digit numeric, zero-padded. Cryptographically random.
    SecureRandom.random_number(10 ** OTP_CODE_LENGTH).to_s.rjust(OTP_CODE_LENGTH, '0')
  end

  def fully_authorized?
    if !active?
      return false
    end

    if requires_otp?
      return mfa_verified_at.present?
    end

    true
  end

  def requires_otp?
    if authenticatable.respond_to?(:otp_enabled_at) && authenticatable.otp_enabled_at.present?
      return true
    end

    if current_company.present? && current_company.require_2fa?
      return true
    end

    false
  end

  private
    def credentials_match_transport
      if web? && jti.present?
        errors.add(:jti, 'must be blank for web sessions')
      end

      if mobile? && remember_token_digest.present?
        errors.add(:remember_token_digest, 'must be blank for mobile sessions')
      end
    end
end

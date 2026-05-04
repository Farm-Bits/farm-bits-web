class UserSession < ApplicationRecord
  TRANSPORTS = %w[web mobile].freeze

  WEB_DEFAULT_EXPIRY    = 14.days
  WEB_REMEMBERED_EXPIRY = 90.days
  MOBILE_EXPIRY         = 60.days
  REMEMBER_TOKEN_LENGTH = 32
  LAST_SEEN_THROTTLE    = 1.minute

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
    authenticatable.respond_to?(:otp_enabled_at) &&
      authenticatable.otp_enabled_at.present?
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

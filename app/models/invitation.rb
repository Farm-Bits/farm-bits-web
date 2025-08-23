class Invitation < ApplicationRecord
  audited

  belongs_to :inviter, polymorphic: true
  belongs_to :client, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: RoleManageable::ROLES.keys }, if: -> { inviter_type == 'User' }
  validates :role, absence: true, if: -> { inviter_type == 'AdminUser' }
  validates :status, inclusion: { in: %w[pending expired cancelled accepted] }
  validates :client, presence: true, if: -> { inviter_type == 'User' }
  validates :client, absence: true, if: -> { inviter_type == 'AdminUser' }
  validate :user_not_already_member, on: :create
  validate :admin_user_not_already_exists, on: :create

  before_create :generate_token
  before_create :set_expires_at
  after_create :send_invitation_email

  def expired?
    expires_at < Time.current
  end

  def accept!(acceptor)
    if expired?
      return { success: false, error: 'Invitation has expired' }
    end

    if status != 'pending'
      return { success: false, error: 'Invitation is not pending' }
    end

    if acceptor.email != email
      return { success: false, error: 'Email mismatch' }
    end

    ActiveRecord::Base.transaction do
      if inviter_type == 'User'
        accept_user_invitation!(acceptor)
      elsif inviter_type == 'AdminUser'
        accept_admin_user_invitation!(acceptor)
      else
        Rails.logger.warn "Unknown inviter type: #{inviter_type}"
      end

      update!(status: 'accepted', accepted_at: Time.current)
    end

    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  rescue => e
    Rails.logger.error "Failed to accept invitation #{id}: #{e.message}"
    { success: false, error: 'Failed to accept invitation' }
  end

  def resend
    if status != 'pending'
      return { success: false, error: 'Invitation is not pending' }
    end

    generate_token
    set_expires_at

    if save
      send_invitation_email
      { success: true }
    else
      { success: false, errors: errors.full_messages }
    end
  end

  def cancel!
    update!(status: 'cancelled')
  end

  def accept_url
    Rails.application.routes.url_helpers.accept_invitation_url(
      token: token,
      host: Rails.application.config.action_mailer.default_url_options[:host],
      protocol: Rails.application.config.action_mailer.default_url_options[:protocol] || 'https'
    )
  end

  private
    def user_not_already_member
      if inviter_type != 'User' || !client.present?
        return
      end

      existing_user = User.find_by(email: email)
      if existing_user&.member_of?(client)
        errors.add(:email, 'is already a member of this organization')
      end
    end

    def admin_user_not_already_exists
      if inviter_type != 'AdminUser'
        return
      end

      existing_admin = AdminUser.find_by(email: email)
      if existing_admin
        errors.add(:email, 'admin user already exists')
      end
    end

    def accept_user_invitation!(user)
      if !user.is_a?(User)
        raise ArgumentError, 'User required for User invitation'
      end

      client_user = ClientUser.find_or_initialize_by(client: client, user: user)
      client_user.role = role
      client_user.active = true
      client_user.save!
    end

    def accept_admin_user_invitation!(admin_user)
      if !admin_user.is_a?(AdminUser)
        raise ArgumentError, 'AdminUser required for AdminUser invitation'
      end

      admin_user.update!(active: true) unless admin_user.active?
    end

    def generate_token
      self.token = SecureRandom.urlsafe_base64(32)
    end

    def set_expires_at
      self.expires_at = 7.days.from_now
    end

    def send_invitation_email
      InvitationMailer.invite(self).deliver_later
    end
end
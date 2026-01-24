class Invitation < ApplicationRecord
  audited
  include Roleable

  belongs_to :inviter, polymorphic: true
  belongs_to :company, optional: true

  has_many :invitation_sites, dependent: :destroy
  has_many :sites, through: :invitation_sites
  accepts_nested_attributes_for :sites

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, if: -> { inviter_type == 'User' }
  validates :role, absence: true, if: -> { inviter_type == 'AdminUser' }
  validates :status, inclusion: { in: %w[pending expired accepted] }
  validates :company, presence: true, if: -> { inviter_type == 'User' }
  validates :company, absence: true, if: -> { inviter_type == 'AdminUser' }
  validate :user_not_already_member, on: :create
  validate :admin_user_not_already_exists, on: :create

  enum :role, Roleable::ROLE_IDS

  before_create :generate_token
  before_create :set_expires_at
  after_create :send_invitation_email

  def pending?
    status == 'pending'
  end

  def accepted?
    status == 'accepted'
  end

  def expired?
    expires_at < Time.current
  end

  def can_be_resent?
    pending?
  end

  def accept_url
    Rails.application.routes.url_helpers.accept_invitation_url(token: token)
  end

  def accept!(user)
    if accepted?
      return { success: false, error: 'Invitation already accepted' }
    end

    if expired?
      return { success: false, error: 'Invitation has expired' }
    end

    ActiveRecord::Base.transaction do
      case inviter_type
      when 'User'
        accept_user_invitation!(user)
      when 'AdminUser'
        accept_admin_user_invitation!(user)
      else
        raise ArgumentError, "Unknown inviter type: #{inviter_type}"
      end

      update!(status: 'accepted', accepted_at: Time.current)
    end

    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.record.errors.full_messages.to_sentence }
  rescue => e
    { success: false, error: 'An error occurred while accepting the invitation' }
  end

  def resend
    if accepted?
      return { success: false, error: 'Cannot resend accepted invitation' }
    end

    if expired?
      return { success: false, error: 'Cannot resend expired invitation' }
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

  private
    def user_not_already_member
      if inviter_type != 'User' || !company.present?
        return
      end

      existing_invitation = Invitation.where(email: email, company: company)
        .where.not(status: 'accepted')
        .first
      if existing_invitation
        errors.add(:email, 'has already been invited to this organization')
      end

      existing_user = User.find_by(email: email)
      if existing_user&.member_of?(company)
        errors.add(:email, 'is already a member of this organization')
      end
    end

    def admin_user_not_already_exists
      if inviter_type != 'AdminUser'
        return
      end

      existing_invitation = Invitation.where(email: email, inviter_type: 'AdminUser')
        .where.not(status: 'accepted')
        .first
      if existing_invitation
        errors.add(:email, 'has already been invited')
      end

      existing_admin = AdminUser.find_by(email: email)
      if existing_admin
        errors.add(:email, 'admin user already exists')
      end
    end

    def accept_user_invitation!(user)
      if !user.is_a?(User)
        raise ArgumentError, 'Invalid user type for company invitation'
      end

      company_user = company.company_users.find_or_initialize_by(user: user)
      if company_user.persisted?
        raise ActiveRecord::RecordInvalid, 'User is already a member of this company'
      else
        company_user.assign_attributes(role: role)
        sites.each do |site|
          company_user.company_user_sites.build(site: site)
        end
        company_user.save!
      end
    end

    def accept_admin_user_invitation!(admin_user)
      if !admin_user.is_a?(AdminUser)
        raise ArgumentError, 'Invalid user type for admin invitation'
      end
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
class Invitation < ApplicationRecord
  audited

  belongs_to :client
  belongs_to :inviter, class_name: 'User'

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :client_id, message: "has already been invited to this client" }
  validates :role, inclusion: { in: RoleManageable.invitable_roles }
  validates :status, inclusion: { in: %w[pending canceled accepted expired] }

  enum status: {
    pending: 0,
    canceled: 1,
    accepted: 2,
    declined: 4,
    expired: 4
  }

  before_create :generate_token, :set_expiration

  def expired?
    expires_at < Time.current
  end

  def accept!(user)
    if !pending? || expired?
      return false
    end

    ActiveRecord::Base.transaction do
      client.add_user(user, role: role)
      update!(status: 'accepted')
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def decline!
    if !pending?
      return false
    end

    update!(status: 'declined')
  end

  private
    def generate_token
      self.token = SecureRandom.urlsafe_base64(32)
    end

    def set_expiration
      self.expires_at = 7.days.from_now
    end
end

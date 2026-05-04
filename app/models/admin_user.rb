class AdminUser < ApplicationRecord
  audited

  # Include default devise modules. Others available are:
  #  :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :validatable, :trackable,
    :confirmable, :lockable

  encrypts :otp_secret

  has_many :user_sessions, as: :authenticatable, dependent: :destroy

  has_many :invitations, as: :inviter, dependent: :nullify

  after_commit :send_password_change_notification, if: :saved_change_to_encrypted_password?, on: :update

  def active_for_authentication?
    super && active
  end

  def inactive_message
    active ? super : 'Your account is disabled'
  end

  private
    def send_password_change_notification
      if persisted?
        Devise::Mailer.password_change(self).deliver_later
      end
    end
end

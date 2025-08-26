class AdminUser < ApplicationRecord
  audited

  # Include default devise modules. Others available are:
  #  :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
    :trackable, :confirmable, :lockable

  after_commit :send_password_change_notification, if: :saved_change_to_encrypted_password?, on: :update

  class << self
    def ransackable_attributes(auth_object=nil)
      [
        "id",
        "name",
        "email",
        "encrypted_password",
        "reset_password_token",
        "reset_password_sent_at",
        "remember_created_at",
        "sign_in_count",
        "current_sign_in_at",
        "last_sign_in_at",
        "current_sign_in_ip",
        "last_sign_in_ip",
        "confirmation_token",
        "confirmed_at",
        "confirmation_sent_at",
        "unconfirmed_email",
        "failed_attempts",
        "unlock_token",
        "locked_at",
        "active",
        "created_at",
        "updated_at"
      ]
    end
  end

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

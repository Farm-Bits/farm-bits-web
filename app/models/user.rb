class User < ApplicationRecord
  audited
  include Roleable

  # Include default devise modules. Others available are:
  #  :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :validatable,
    :trackable, :confirmable, :lockable

  encrypts :otp_secret

  has_many :user_sessions, as: :authenticatable, dependent: :destroy

  has_many :company_users, dependent: :destroy

  has_many :companies, through: :company_users

  has_many :invitations, as: :inviter, dependent: :nullify

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { case_sensitive: false }
  validate :cannot_deactivate_last_admin_user, if: :active_changed_to_false?

  attr_accessor :company_attributes, :current_company_user

  before_validation :normalize_email
  after_create :create_company_and_site_from_attributes
  before_destroy :prevent_destroy_last_admin_user
  after_destroy :destroy_received_invitations
  after_commit :send_password_change_notification, if: :saved_change_to_encrypted_password?, on: :update

  def active_for_authentication?
    super && active
  end

  def inactive_message
    active ? super : 'Your account is disabled'
  end

  def member_of?(company)
    company.company_users.any? { |cu| cu.user == self && !cu.marked_for_destruction? }
  end

  def active_companies_connections
    companies.joins(:company_users)
      .where(company_users: { user: self })
      .where(active: true)
      .distinct
  end

  def company_user_for(company)
    company_id = company.is_a?(Company) ? company.id : company.to_i

    @company_user_cache ||= {}

    if @company_user_cache.key?(company_id)
      return @company_user_cache[company_id]
    end

    if company_users.loaded?
      company_user = company_users.find { |cu| cu.company_id == company_id }
    else
      company_user = company_users.find_by(company_id: company_id)
    end

    @company_user_cache[company_id] = company_user
    company_user
  end

  def last_admin_for_any_company?
    company_users.where(role: Roleable::ROLE_IDS[:admin]).any? do |admin_company_user|
      company = admin_company_user.company
      other_admins = company.company_users
        .where.not(user_id: id)
        .where(role: Roleable::ROLE_IDS[:admin])

      other_admins.empty?
    end
  end

  private
    def active_changed_to_false?
      active_changed? && !active
    end

    def create_company_and_site_from_attributes
      if !company_attributes.present?
        return
      end

      begin
        company_attrs = company_attributes.merge(
          company_users_attributes: [{ user: self, role: Roleable::ROLE_IDS[:admin] }],
        )
        Company.create!(company_attrs)
      rescue ActiveRecord::RecordInvalid => e
        if e.record != self
          if e.record.is_a?(Company)
            e.record.errors.each do |error|
              errors.add(:company, "#{error.attribute} #{error.message}")
            end
          elsif e.record.is_a?(Site)
            e.record.errors.each do |error|
              errors.add(:site, "#{error.attribute} #{error.message}")
            end
          end
        end

        raise e
      end
    end

    def cannot_deactivate_last_admin_user
      if last_admin_for_any_company?
        errors.add(:base, 'Cannot deactivate user who is the last admin for one or more companies')
      end
    end

    def normalize_email
      if email.present?
        self.email = email.to_s.downcase.strip
      end
    end

    def prevent_destroy_last_admin_user
      if last_admin_for_any_company?
        errors.add(:base, 'Cannot destroy user who is the last admin for one or more companies')
        throw(:abort)
      end
    end

    def destroy_received_invitations
      invitations.destroy_all
      invitations_received = Invitation.where(email: email, inviter_type: 'User')
      invitations_received.destroy_all
    end

    def send_password_change_notification
      if persisted?
        Devise::Mailer.password_change(self).deliver_later
      end
    end
end

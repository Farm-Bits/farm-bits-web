class User < ApplicationRecord
  audited
  include Roleable

  has_many :client_users, dependent: :destroy

  has_many :clients, through: :client_users

  has_many :site_users, dependent: :destroy
  has_many :sites, through: :site_users
  accepts_nested_attributes_for :sites

  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'inviter_id'

  # Include default devise modules. Others available are:
  #  :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
    :validatable, :trackable, :confirmable, :lockable

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { case_sensitive: false }
  validate :cannot_deactivate_last_admin_user, if: :active_changed_to_false?

  attr_accessor :client_attributes, :current_client_user

  after_create :create_client_and_site_from_attributes
  before_destroy :prevent_destroy_last_admin_user
  after_commit :send_password_change_notification, if: :saved_change_to_encrypted_password?, on: :update

  def active_for_authentication?
    super && active
  end

  def inactive_message
    active ? super : 'Your account is disabled'
  end

  def member_of?(client)
    client.client_users.any? { |cu| cu.user == self && cu.active && !cu.marked_for_destruction? }
  end

  def active_clients_connections
    clients.joins(:client_users)
      .where(client_users: { user: self, active: true })
      .where(active: true)
  end

  def client_user_for(client)
    client_id = client.is_a?(Client) ? client.id : client.to_i

    @client_user_cache ||= {}

    if @client_user_cache.key?(client_id)
      return @client_user_cache[client_id]
    end

    if client_users.loaded?
      client_user = client_users.find { |cu| cu.client_id == client_id }
    else
      client_user = client_users.find_by(client_id: client_id)
    end

    @client_user_cache[client_id] = client_user
    client_user
  end

  def last_admin_for_any_client?
    client_users.where(role: Roleable::ROLE_IDS[:admin], active: true).any? do |admin_client_user|
      client = admin_client_user.client
      other_active_admins = client.client_users
        .where.not(user_id: id)
        .where(role: Roleable::ROLE_IDS[:admin], active: true)

      other_active_admins.empty?
    end
  end

  private
    def active_changed_to_false?
      active_changed? && !active
    end

    def create_client_and_site_from_attributes
      if !client_attributes.present?
        return
      end

      begin
        client_attrs = client_attributes.merge(
          client_users_attributes: [{ user: self, role: Roleable::ROLE_IDS[:admin] }],
        )
        client = Client.create!(client_attrs)
      rescue ActiveRecord::RecordInvalid => e
        if e.record != self
          if e.record.is_a?(Client)
            e.record.errors.each do |error|
              errors.add(:client, "#{error.attribute} #{error.message}")
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
      if last_admin_for_any_client?
        errors.add(:base, 'Cannot deactivate user who is the last admin for one or more companies')
      end
    end

    def prevent_destroy_last_admin_user
      if last_admin_for_any_client?
        errors.add(:base, 'Cannot destroy user who is the last admin for one or more companies')
        throw(:abort)
      end
    end

    def send_password_change_notification
      if persisted?
        Devise::Mailer.password_change(self).deliver_later
      end
    end
end

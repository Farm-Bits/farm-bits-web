class User < ApplicationRecord
  audited

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

  attr_accessor :client_attributes, :current_client_user

  after_create :create_client_and_site_from_attributes
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

    def with_client_context(client)
      includes(:client_users)
        .joins(:client_users)
        .where(active: true, client_users: { client: client, active: true })
        .map { |user| user.with_client_context(client) }
    end
  end

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
    clients.where(
      id: client_users.select(:client_id).where(active: true),
      active: true
    )
  end

  def accessible_sites_for_client(client)
    client_user = client_users.find_by(client: client, active: true)
    if !client_user
      return []
    end

    if client_user.can_access_all_sites?
      client.sites.where(active: true)
    else
      sites.joins(:site_users)
           .where(client: client, active: true)
           .where(site_users: { active: true })
    end
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

  def with_client_context(client)
    self.current_client_user = client_user_for(client)
    self
  end

  def role_for_current_client
    current_client_user&.role
  end

  def active_for_current_client?
    current_client_user&.active? || false
  end

  private
    def create_client_and_site_from_attributes
      if !client_attributes.present?
        return
      end

      begin
        client_attrs = client_attributes.merge(
          client_users_attributes: [{ user: self, role: RoleManageable.highest_role }],
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

    def send_password_change_notification
      if persisted?
        Devise::Mailer.password_change(self).deliver_later
      end
    end
end

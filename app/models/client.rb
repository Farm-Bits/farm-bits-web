class Client < ApplicationRecord
  audited
  include RoleManageable

  has_many :client_users, dependent: :destroy
  accepts_nested_attributes_for :client_users

  has_many :users, through: :client_users

  has_many :sites, dependent: :destroy
  accepts_nested_attributes_for :sites, :allow_destroy => true

  has_many :invitations, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :subdomain, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-z0-9\-]+\z/ }
  validate :must_have_at_least_one_active_owner
  validate :must_have_at_least_one_active_site

  attr_accessor :site_attributes

  before_validation :set_default_subdomain, on: :create
  before_validation :set_default_color, on: :create
  before_validation :create_site_from_attributes, on: :create
  before_destroy :handle_orphaned_users, prepend: true

  private
    def must_have_at_least_one_active_owner
      highest_role = RoleManageable.highest_role

      active_owners = client_users.reject(&:marked_for_destruction?).select do |cu|
        cu.role == highest_role && cu.active
      end

      if active_owners.empty?
        errors.add(:base, 'must have at least one active owner')
      end
    end

    def must_have_at_least_one_active_site
      active_sites = sites.reject(&:marked_for_destruction?).select(&:active)

      if active_sites.empty?
        errors.add(:base, 'must have at least one active site')
      end
    end

    def set_default_subdomain
      if subdomain.present? || !name.present?
        return
      end

      self.subdomain = name.parameterize
    end

    def set_default_color
      if color.present?
        return
      end

      red = 128 + rand(128)
      green = 128 + rand(128)
      blue = 128 + rand(128)
      self.color = "#%02x%02x%02x" % [red, green, blue]
    end

    def create_site_from_attributes
      if !site_attributes.present?
        return
      end

      sites.build(site_attributes)
    end

    def handle_orphaned_users
      client_users.includes(:user).each do |client_user|
        user = client_user.user

        other_client_connections = user.client_users.where.not(client_id: id)
        if other_client_connections.empty?
          user.destroy!
        end
      end
    end
end

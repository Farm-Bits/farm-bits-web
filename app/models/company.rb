class Company < ApplicationRecord
  audited
  include Roleable

  has_many :company_users, dependent: :destroy
  accepts_nested_attributes_for :company_users

  has_many :users, through: :company_users

  has_many :sites, dependent: :destroy
  accepts_nested_attributes_for :sites, :allow_destroy => true

  has_many :invitations, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :color, presence: true, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: 'must be a valid hex color (e.g., #FF0000)' }
  validate :must_have_at_least_one_admin
  validate :must_have_at_least_one_site

  attr_accessor :site_attributes

  before_validation :create_site_from_attributes, on: :create
  before_validation :handle_color_assignment
  before_destroy :handle_orphaned_users, prepend: true

  def company_user_for(user)
    user_id = user.is_a?(User) ? user.id : user.to_i

    @company_user_cache ||= {}

    if @company_user_cache.key?(user_id)
      return @company_user_cache[user_id]
    end

    if company_users.loaded?
      company_user = company_users.find { |cu| cu.user_id == user_id }
    else
      company_user = company_users.find_by(user_id: user_id)
    end

    @company_user_cache[user_id] = company_user
    company_user
  end

  private
    def must_have_at_least_one_admin
      admins = company_users.reject(&:marked_for_destruction?).select do |cu|
        cu.role == Roleable::ROLE_IDS[:admin]
      end

      if admins.empty?
        errors.add(:base, 'must have at least one admin')
      end
    end

    def must_have_at_least_one_site
      active_sites = sites.reject(&:marked_for_destruction?)

      if active_sites.empty?
        errors.add(:base, 'must have at least one site')
      end
    end

    def create_site_from_attributes
      if !site_attributes.present?
        return
      end

      sites.build(site_attributes)
    end

    def handle_color_assignment
      if new_record?
        if color.blank?
          red = 128 + rand(128)
          green = 128 + rand(128)
          blue = 128 + rand(128)
          self.color = "#%02x%02x%02x" % [red, green, blue]
        end
      else
        if color.blank?
          self.color = color_was
        end
      end
    end

    def handle_orphaned_users
      company_users.includes(:user).each do |company_user|
        user = company_user.user

        other_company_connections = user.company_users.where.not(company_id: id)
        if other_company_connections.empty?
          user.destroy!
        end
      end
    end
end

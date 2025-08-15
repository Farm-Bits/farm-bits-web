module RoleManageable
  extend ActiveSupport::Concern

  ROLES = {
    'owner' => {
      level: 4,
      description: 'Full access, billing, delete client',
      can_access_all_sites: true,
      can_manage_users: true,
      can_manage_billing: true,
      can_create_sites: true,
      can_manage_client_settings: true
    },
    'admin' => {
      level: 3,
      description: 'All sites, manage users',
      can_access_all_sites: true,
      can_manage_users: true,
      can_manage_billing: false,
      can_create_sites: true,
      can_manage_client_settings: true
    },
    'manager' => {
      level: 2,
      description: 'Assigned sites with edit access',
      can_access_all_sites: false,
      can_manage_users: false,
      can_manage_billing: false,
      can_create_sites: true,
      can_manage_client_settings: false
    },
    'viewer' => {
      level: 1,
      description: 'Assigned sites, read-only',
      can_access_all_sites: false,
      can_manage_users: false,
      can_manage_billing: false,
      can_create_sites: false,
      can_manage_client_settings: false
    }
  }.freeze

  class << self
    def highest_role
      ROLES.max_by { |_, config| config[:level] }.first
    end

    def invitable_roles
      ROLES.select { |_, config| config[:level] < ROLES[highest_role][:level] }.keys
    end

    def valid_role?(role)
      ROLES.key?(role.to_s)
    end
  end

  def role_config
    ROLES[role] || {}
  end

  def role_level
    ROLES[role]&.dig(:level) || 0
  end

  def can_access_all_sites?
    role_config[:can_access_all_sites] == true
  end

  def can_manage_users?
    role_config[:can_manage_users] == true
  end

  def can_manage_billing?
    role_config[:can_manage_billing] == true
  end

  def can_create_sites?
    role_config[:can_create_sites] == true
  end

  def can_manage_client_settings?
    role_config[:can_manage_client_settings] == true
  end

  def has_role_level_or_higher?(level)
    role_level >= level
  end
end

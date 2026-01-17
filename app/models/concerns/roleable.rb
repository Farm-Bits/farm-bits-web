module Roleable
  extend ActiveSupport::Concern

  ROLES = {
    admin: {
      id: 'admin',
      name: 'Admin',
      description: 'Full access to all sites, management of company settings'
    },
    site_admin: {
      id: 'site_admin',
      name: 'Site Admin',
      description: 'Full access on assigned sites'
    },
    manager: {
      id: 'manager',
      name: 'Manager',
      description: 'Control on assigned sites'
    },
    viewer: {
      id: 'viewer',
      name: 'Viewer',
      description: 'Assigned sites, read-only'
    }
  }.freeze

  ROLE_IDS = ROLES.transform_values { |v| v[:id] }.freeze
end

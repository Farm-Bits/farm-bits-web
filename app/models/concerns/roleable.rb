module Roleable
  extend ActiveSupport::Concern

  ROLES = {
    admin: {
      id: 'admin',
      name: 'Admin',
      description: 'Full access to all sites, management of company settings',
      level: 5,
      site_specific: false
    },
    site_admin: {
      id: 'site_admin',
      name: 'Site Admin',
      description: 'Full access on assigned sites',
      level: 4,
      site_specific: true
    },
    manager: {
      id: 'manager',
      name: 'Manager',
      description: 'Control on assigned sites',
      level: 3,
      site_specific: true
    },
    viewer: {
      id: 'viewer',
      name: 'Viewer',
      description: 'Assigned sites, read-only',
      level: 2,
      site_specific: true
    }
  }.freeze

  ROLE_IDS = ROLES.transform_values { |v| v[:id] }.freeze
end

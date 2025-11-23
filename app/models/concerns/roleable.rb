module Roleable
  extend ActiveSupport::Concern

  ROLES = {
    admin: {
      id: 'admin',
      name: 'Admin',
      description: 'Full access to all sites, management of company settings'
    },
    manager: {
      id: 'manager',
      name: 'Manager',
      description: 'Assigned sites with edit access'
    },
    viewer: {
      id: 'viewer',
      name: 'Viewer',
      description: 'Assigned sites, read-only'
    }
  }.freeze

  ROLE_IDS = ROLES.transform_values { |v| v[:id] }.freeze
end

module Roleable
  extend ActiveSupport::Concern

  ROLES = {
    admin: 'admin',
    manager: 'manager',
    viewer: 'viewer'
  }.freeze
end

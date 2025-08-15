class ClientUser < ApplicationRecord
  audited
  include RoleManageable

  belongs_to :client
  belongs_to :user

  validates :role, inclusion: { in: ROLES.keys }
  validates :client_id, uniqueness: { scope: :user_id }
  validates :user_id, uniqueness: { scope: :client_id }
end

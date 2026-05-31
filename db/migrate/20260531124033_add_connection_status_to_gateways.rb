class AddConnectionStatusToGateways < ActiveRecord::Migration[7.2]
  def change
    add_column :gateways, :connection_status, :string, null: false, default: 'unknown', after: :password
    add_column :gateways, :connection_status_updated_at, :datetime, after: :connection_status

    add_index :gateways, :connection_status
  end
end

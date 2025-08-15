class CreateInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :invitations do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :inviter, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.string :email, null: false
      t.string :token, null: false
      t.string :role, default: 'viewer'
      t.integer :status, default: 0
      t.datetime :expired_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, [:client_id, :email], unique: true
  end
end

class CreateClientUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :client_users do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :role, default: 'viewer'

      t.timestamps
    end

    add_index :client_users, [:client_id, :user_id], unique: true
  end
end

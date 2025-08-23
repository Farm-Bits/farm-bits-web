class CreateInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :invitations do |t|
      t.string :email, null: false
      t.string :role
      t.string :status, null: false, default: 'pending'
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.references :inviter, null: false, polymorphic: true
      t.references :client, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :invitations, :email
    add_index :invitations, :token, unique: true
  end
end

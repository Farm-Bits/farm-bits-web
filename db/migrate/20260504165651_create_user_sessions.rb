class CreateUserSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_sessions do |t|
      t.string :transport, null: false
      t.string :remember_token_digest
      t.string :jti
      t.string :client_name
      t.string :user_agent
      t.string :ip_address
      t.string :pending_otp_digest
      t.integer :pending_otp_attempts, default: 0, null: false
      t.datetime :pending_otp_expires_at
      t.datetime :last_seen_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :mfa_verified_at
      t.references :current_company, foreign_key: { to_table: :companies }
      t.references :authenticatable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :user_sessions, :jti, unique: true
    add_index :user_sessions, [:authenticatable_type, :authenticatable_id, :revoked_at]
    add_index :user_sessions, :expires_at

    remove_column :users, :remember_created_at, :datetime
    remove_column :admin_users, :remember_created_at, :datetime

    add_column :companies, :require_2fa, :boolean, default: false, null: false, after: :color

    add_column :users, :otp_enabled_at, :datetime, after: :encrypted_password
    add_column :users, :otp_backup_codes_digests, :json, after: :otp_enabled_at

    add_column :admin_users, :otp_enabled_at, :datetime, after: :encrypted_password
    add_column :admin_users, :otp_backup_codes_digests, :json, after: :otp_enabled_at

    add_index :users, :otp_enabled_at
    add_index :admin_users, :otp_enabled_at
  end
end

class CreateUserSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_sessions do |t|
      t.string :transport, null: false
      t.string :remember_token_digest
      t.string :jti
      t.string :client_name
      t.string :user_agent
      t.string :ip_address
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

    # Drop rememberable columns — replaced by user_sessions.remember_token_digest
    remove_column :users, :remember_created_at, :datetime
    remove_column :admin_users, :remember_created_at, :datetime

    # 2FA: TOTP secret (encrypted), enabled flag, backup codes
    add_column :users, :otp_secret, :text, after: :encrypted_password  # encrypted; text for ciphertext length
    add_column :users, :otp_enabled_at, :datetime, after: :otp_secret
    add_column :users, :otp_backup_codes_digests, :json, after: :otp_enabled_at

    add_column :admin_users, :otp_secret, :text, after: :encrypted_password
    add_column :admin_users, :otp_enabled_at, :datetime, after: :otp_secret
    add_column :admin_users, :otp_backup_codes_digests, :json, after: :otp_enabled_at

    add_index :users, :otp_enabled_at
    add_index :admin_users, :otp_enabled_at
  end
end

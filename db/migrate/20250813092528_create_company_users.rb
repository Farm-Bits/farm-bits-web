class CreateCompanyUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :company_users do |t|
      t.references :company, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :role, default: 'viewer'

      t.timestamps
    end

    add_index :company_users, [:company_id, :user_id], unique: true
  end
end

class CreateCompanyUserSites < ActiveRecord::Migration[7.2]
  def change
    create_table :company_user_sites do |t|
      t.references :company_user, null: false, foreign_key: { on_delete: :cascade }
      t.references :site, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :company_user_sites, [:company_user_id, :site_id], unique: true
  end
end

class CreateClientUserSites < ActiveRecord::Migration[7.2]
  def change
    create_table :client_user_sites do |t|
      t.references :client_user, null: false, foreign_key: { on_delete: :cascade }
      t.references :site, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :client_user_sites, [:client_user_id, :site_id], unique: true
  end
end

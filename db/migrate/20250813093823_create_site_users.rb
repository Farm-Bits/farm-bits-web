class CreateSiteUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :site_users do |t|
      t.references :site, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :site_users, [:site_id, :user_id], unique: true
  end
end

class CreateSegments < ActiveRecord::Migration[7.0]
  def change
    create_table :segments do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.references :site, null: false, foreign_key: { on_delete: :cascade }
      t.references :client, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :segments, [:site_id, :name], unique: true
  end
end

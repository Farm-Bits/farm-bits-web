class CreatePlcVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :plc_versions do |t|
      t.string :name, null: false
      t.string :version_code, null: false
      t.text :description
      t.boolean :is_latest, null: false, default: false
      t.boolean :is_supported, null: false, default: true
      t.string :handler_class, null: false
      t.references :model, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :plc_versions, [:model_id, :name], unique: true
    add_index :plc_versions, [:model_id, :is_latest]
    add_index :plc_versions, :is_supported
  end
end

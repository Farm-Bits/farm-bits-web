class CreatePlcVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :plc_versions do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_reference :plc_versions, :plc_version, foreign_key: { on_delete: :cascade }, null: true, after: :description
    add_reference :plc_versions, :plc_model, foreign_key: { on_delete: :cascade }, after: :description
  end
end

class CreateInterfaces < ActiveRecord::Migration[7.0]
  def change
    create_table :interfaces do |t|
      t.string :name, null: false
      t.string :communication_type, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.references :plc_version, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :interfaces, [:plc_version_id, :name], unique: true
    add_index :interfaces, [:plc_version_id, :communication_type]
    add_index :interfaces, [:plc_version_id, :position]
  end
end

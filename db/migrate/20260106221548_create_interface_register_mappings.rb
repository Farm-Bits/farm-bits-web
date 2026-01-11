class CreateInterfaceRegisterMappings < ActiveRecord::Migration[7.2]
  def change
    create_table :interface_register_mappings do |t|
      t.string :category, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.references :interface, null: false, foreign_key: { on_delete: :cascade }
      t.references :register_template, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :interface_register_mappings, [:interface_id, :category]
    add_index :interface_register_mappings, [:interface_id, :position]
  end
end

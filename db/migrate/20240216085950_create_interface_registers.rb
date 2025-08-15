class CreateInterfaceRegisters < ActiveRecord::Migration[7.0]
  def change
    create_table :interface_registers do |t|
      t.references :interface, null: false, foreign_key: { on_delete: :cascade }
      t.references :register, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end

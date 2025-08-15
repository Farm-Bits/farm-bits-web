class CreateInterfaces < ActiveRecord::Migration[7.0]
  def change
    create_table :interfaces do |t|
      t.string :name, null: false
      t.string :communication_type, null: false
      t.references :register, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_reference :interfaces, :plc_version, null: false, foreign_key: { on_delete: :cascade }, after: :register_id
    add_index :interfaces, :communication_type
  end
end

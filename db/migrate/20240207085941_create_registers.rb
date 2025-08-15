class CreateRegisters < ActiveRecord::Migration[7.0]
  def change
    create_table :registers do |t|
      t.string :name, null: false
      t.text :description
      t.integer :address, null: false
      t.integer :min_value
      t.integer :max_value, :limit => 8
      t.references :plc_version, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end

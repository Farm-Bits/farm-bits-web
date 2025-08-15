class CreateTerminals < ActiveRecord::Migration[7.0]
  def change
    create_table :terminals do |t|
      t.string :imei, null: false
      t.string :iccid, null: false
      t.string :phone_number, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_reference :terminals, :site, foreign_key: { on_delete: :cascade }, after: :phone_number
    add_reference :terminals, :terminal_model, foreign_key: true, after: :id
  end
end

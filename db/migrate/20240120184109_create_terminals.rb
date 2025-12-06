class CreateTerminals < ActiveRecord::Migration[7.0]
  def change
    create_table :terminals do |t|
      t.string :label, null: false
      t.string :name, null: false
      t.string :imei, null: false
      t.string :serial_number, null: false
      t.string :iccid, null: false
      t.string :phone_number, null: false
      t.string :private_ip, null: false
      t.text :username, null: false
      t.text :password, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_reference :terminals, :site, foreign_key: true, after: :password
    add_reference :terminals, :client, foreign_key: true, after: :site_id
    add_reference :terminals, :terminal_model, foreign_key: true, after: :id
  end
end

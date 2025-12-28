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
      t.datetime :last_seen_at
      t.boolean :active, null: false, default: true
      t.references :model, null: false, foreign_key: true
      t.references :site, foreign_key: true
      t.references :client, foreign_key: true

      t.timestamps
    end

    add_index :terminals, :imei, unique: true
    add_index :terminals, :serial_number, unique: true
    add_index :terminals, :iccid, unique: true
    add_index :terminals, :active
    add_index :terminals, [:client_id, :active]
    add_index :terminals, [:site_id, :active]
  end
end

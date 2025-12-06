class CreatePlcs < ActiveRecord::Migration[7.0]
  def change
    create_table :plcs do |t|
      t.string :label, null: false
      t.string :name, null: false
      t.string :serial_number, null: false
      t.references :plc_version, null: false, foreign_key: true
      t.integer :slave, null: false
      t.string :private_ip
      t.string :host
      t.integer :port
      t.text :username, null: false
      t.text :password, null: false
      t.references :terminal, foreign_key: true
      t.references :client, foreign_key: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end

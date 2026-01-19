class CreatePlcs < ActiveRecord::Migration[7.0]
  def change
    create_table :plcs do |t|
      t.string :label, null: false
      t.string :name, null: false
      t.string :serial_number, null: false
      t.integer :slave, null: false
      t.string :private_ip
      t.string :host
      t.integer :port
      t.text :username, null: false
      t.text :password, null: false
      t.text :web_username, null: false
      t.text :web_password, null: false
      t.datetime :last_seen_at
      t.boolean :active, null: false, default: true
      t.references :model, null: false, foreign_key: true
      t.references :plc_version, null: false, foreign_key: true
      t.references :terminal, foreign_key: true
      t.references :site, foreign_key: true

      t.timestamps
    end

    add_index :plcs, :serial_number, unique: true
    add_index :plcs, :active
    add_index :plcs, [:terminal_id, :active]
  end
end

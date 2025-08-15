class CreateDevices < ActiveRecord::Migration[7.0]
  def change
    create_table :devices do |t|
      t.string :name, null: false
      t.references :device_type, null: false, foreign_key: true
      t.references :interface, foreign_key: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end

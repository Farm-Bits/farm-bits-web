class CreateDeviceTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :device_types do |t|
      t.string :name, null: false
      t.string :communication_type, null: false
      t.string :color

      t.timestamps
    end

    add_index :device_types, :communication_type
  end
end

class CreateTerminalManufacturers < ActiveRecord::Migration[7.0]
  def change
    create_table :terminal_manufacturers do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end

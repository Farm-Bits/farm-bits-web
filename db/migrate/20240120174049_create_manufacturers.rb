class CreateManufacturers < ActiveRecord::Migration[7.0]
  def change
    create_table :manufacturers do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :manufacturers, :name, unique: true
  end
end

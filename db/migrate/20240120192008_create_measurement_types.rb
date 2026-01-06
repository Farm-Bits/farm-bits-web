class CreateMeasurementTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :measurement_types do |t|
      t.string :name, null: false, unique: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :measurement_types, :name, unique: true
  end
end

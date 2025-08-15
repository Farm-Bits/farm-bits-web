class CreateMeasurementPoints < ActiveRecord::Migration[7.0]
  def change
    create_table :measurement_points do |t|
      t.string :name, null: false
      t.text :description
      t.integer :min_value
      t.integer :max_value
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_reference :measurement_points, :device, foreign_key: { on_delete: :cascade }, after: :max_value
    add_reference :measurement_points, :site, foreign_key: { on_delete: :cascade }, after: :device_id
    add_reference :measurement_points, :segment, foreign_key: { on_delete: :cascade }, after: :device_id
    add_reference :measurement_points, :measurement_subtype, foreign_key: true, after: :name
  end
end

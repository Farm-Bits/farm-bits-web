class CreateDeviceTypeMeasurementSubtypes < ActiveRecord::Migration[7.0]
  def change
    create_table :device_type_measurement_subtypes do |t|
      t.references :device_type, null: false, foreign_key: { on_delete: :cascade }
      t.references :measurement_subtype, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end

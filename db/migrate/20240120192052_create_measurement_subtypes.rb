class CreateMeasurementSubtypes < ActiveRecord::Migration[7.0]
  def change
    create_table :measurement_subtypes do |t|
      t.string :name, null: false
      t.string :value_type, null: false
      t.string :chart_type, null: false
      t.string :unit, null: false
      t.string :color

      t.timestamps
    end

    add_index :measurement_subtypes, :value_type
    add_reference :measurement_subtypes, :measurement_type, foreign_key: { on_delete: :cascade }, after: :unit
  end
end

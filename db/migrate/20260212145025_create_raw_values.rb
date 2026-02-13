class CreateRawValues < ActiveRecord::Migration[7.2]
  def change
    create_table :raw_values do |t|
      t.decimal :value, null: false, precision: 20, scale: 6
      t.decimal :scaled_value, null: false, precision: 20, scale: 6
      t.datetime :sample_time, null: false
      t.references :measurement_point, null: false, foreign_key: { on_delete: :cascade }

      t.datetime :created_at, null: false
    end

    add_index :raw_values, [:measurement_point_id, :sample_time]
    add_index :raw_values, :sample_time
  end
end

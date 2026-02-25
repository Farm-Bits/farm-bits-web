class CreatePlcWriteLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :plc_write_logs do |t|
      t.string :source, null: false
      t.string :old_value
      t.string :new_value
      t.string :batch_id, null: false
      t.references :measurement_point, null: false, foreign_key: { on_delete: :cascade }
      t.references :plc, null: false, foreign_key: { on_delete: :cascade }
      t.references :site, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.references :register_template, null: false, foreign_key: { on_delete: :cascade }

      t.datetime :created_at, null: false
    end

    add_index :plc_write_logs, [:plc_id, :created_at]
    add_index :plc_write_logs, [:measurement_point_id, :created_at]
    add_index :plc_write_logs, :batch_id
    add_index :plc_write_logs, :source
    add_index :plc_write_logs, :created_at
  end
end

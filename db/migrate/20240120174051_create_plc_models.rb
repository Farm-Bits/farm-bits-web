class CreatePlcModels < ActiveRecord::Migration[7.0]
  def change
    create_table :plc_models do |t|
      t.string :name, null: false
      t.references :plc_manufacturer, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end

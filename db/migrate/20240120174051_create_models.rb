class CreateModels < ActiveRecord::Migration[7.0]
  def change
    create_table :models do |t|
      t.string :name, null: false
      t.string :device_type, null: false
      t.references :manufacturer, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :models, [:manufacturer_id, :name], unique: true
    add_index :models, :device_type
  end
end

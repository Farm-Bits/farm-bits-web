class CreateTerminalModels < ActiveRecord::Migration[7.0]
  def change
    create_table :terminal_models do |t|
      t.string :name, null: false
      t.references :terminal_manufacturer, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end

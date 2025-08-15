class CreateSegments < ActiveRecord::Migration[7.0]
  def change
    create_table :segments do |t|
      t.string :name, null: false
      t.references :site, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end

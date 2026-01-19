class CreateSegments < ActiveRecord::Migration[7.0]
  def change
    create_table :segments do |t|
      t.string :name, null: false
      t.references :site, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :segments, [:site_id, :name], unique: true
  end
end

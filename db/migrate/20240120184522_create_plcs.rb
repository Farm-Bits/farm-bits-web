class CreatePlcs < ActiveRecord::Migration[7.0]
  def change
    create_table :plcs do |t|
      t.string :name, null: false
      t.references :plc_version, null: false, foreign_key: true
      t.integer :slave, null: false
      t.references :terminal, foreign_key: { on_delete: :cascade }
      t.string :host
      t.integer :port
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end

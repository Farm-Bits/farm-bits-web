class CreateSites < ActiveRecord::Migration[7.0]
  def change
    create_table :sites do |t|
      t.string :name, null: false
      t.string :country, null: false
      t.string :city
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.decimal :geocoded_latitude, precision: 10, scale: 7
      t.decimal :geocoded_longitude, precision: 10, scale: 7
      t.string :time_zone, null: false
      t.references :company, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :sites, [:company_id, :name], unique: true
  end
end

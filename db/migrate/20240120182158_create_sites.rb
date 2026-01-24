class CreateSites < ActiveRecord::Migration[7.0]
  def change
    create_table :sites do |t|
      t.string :name, null: false
      t.string :country, null: false
      t.string :city
      t.float :latitude
      t.float :longitude
      t.float :altitude
      t.string :time_zone, null: false
      t.references :company, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :sites, [:company_id, :name], unique: true
  end
end

class CreateSiteSunData < ActiveRecord::Migration[7.2]
  def change
    create_table :site_sun_data do |t|
      t.date :date, null: false
      t.datetime :sunrise, null: false
      t.datetime :sunset, null: false
      t.datetime :solar_noon
      t.references :site, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :site_sun_data, [:site_id, :date], unique: true
    add_index :site_sun_data, :date
  end
end

class AddIconKeyToMeasurementSubtypes < ActiveRecord::Migration[7.2]
  def change
    add_column :measurement_subtypes, :icon_key, :string, after: :default_color
  end
end

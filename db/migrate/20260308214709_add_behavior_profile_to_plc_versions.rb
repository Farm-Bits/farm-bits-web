class AddBehaviorProfileToPlcVersions < ActiveRecord::Migration[7.2]
  def change
    add_column :plc_versions, :behavior_profile, :string, after: :version_code
    add_index :plc_versions, :behavior_profile

    rename_column :interfaces, :position, :io_number
    change_column_default :interfaces, :io_number, nil

    remove_column :weather_station_api_metrics, :aggregation, :string
  end
end

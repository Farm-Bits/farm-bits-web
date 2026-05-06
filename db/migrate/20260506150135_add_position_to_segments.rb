class AddPositionToSegments < ActiveRecord::Migration[7.2]
  def change
    add_column :segments, :position, :integer, null: false, default: 0, after: :name
  end
end

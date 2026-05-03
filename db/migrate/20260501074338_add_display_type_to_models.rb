class AddDisplayTypeToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :display_type, :string, after: :device_type
  end
end

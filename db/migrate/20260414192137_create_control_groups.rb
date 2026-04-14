class CreateControlGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :control_groups do |t|
      t.string :name, null: false
      t.string :icon_key
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_reference :measurement_subtypes, :control_group, foreign_key: { on_delete: :nullify }, after: :value_type
  end
end

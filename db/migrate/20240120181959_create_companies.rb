class CreateCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :color, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end

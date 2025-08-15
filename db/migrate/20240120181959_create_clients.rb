class CreateClients < ActiveRecord::Migration[7.0]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :color, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :clients, :subdomain, unique: true
  end
end

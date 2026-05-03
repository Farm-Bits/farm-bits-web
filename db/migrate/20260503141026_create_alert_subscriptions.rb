class CreateAlertSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :alert_subscriptions do |t|
      t.references :scope, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.json :channels
      t.string :min_severity, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :alert_subscriptions, [:user_id, :scope_type, :scope_id], unique: true
  end
end

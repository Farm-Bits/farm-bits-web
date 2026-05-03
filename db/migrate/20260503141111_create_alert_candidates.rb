class CreateAlertCandidates < ActiveRecord::Migration[7.2]
  def change
    create_table :alert_candidates do |t|
      t.references :alert_rule, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.datetime :predicate_first_true_at, null: false

      t.timestamps
    end
  end
end

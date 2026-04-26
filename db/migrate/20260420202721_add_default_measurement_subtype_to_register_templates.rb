class AddDefaultMeasurementSubtypeToRegisterTemplates < ActiveRecord::Migration[7.2]
  def change
    add_reference :register_templates,
      :default_measurement_subtype,
      foreign_key: { to_table: :measurement_subtypes, on_delete: :nullify },
      after: :position
  end
end

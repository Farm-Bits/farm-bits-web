class AddReadOnlyEnumKeysToRegisterTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :register_templates, :read_only_enum_keys, :json, after: :enum_values
  end
end

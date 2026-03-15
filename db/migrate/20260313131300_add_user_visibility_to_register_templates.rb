class AddUserVisibilityToRegisterTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :register_templates, :user_visibility, :string, null: false, default: 'hidden', after: :read_only
    change_column_default :register_templates, :user_visibility, nil

    remove_column :register_templates, :sync_field, :string
  end
end

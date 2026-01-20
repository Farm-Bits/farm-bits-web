class CreateInvitationSites < ActiveRecord::Migration[7.2]
  def change
    create_table :invitation_sites do |t|
      t.references :invitation, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true

      t.timestamps
    end

    add_index :invitation_sites, [:invitation_id, :site_id], unique: true
  end
end

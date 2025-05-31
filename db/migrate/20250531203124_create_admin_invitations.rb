class CreateAdminInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_invitations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :admin, null: false, foreign_key: true

      t.timestamps
    end
  end
end

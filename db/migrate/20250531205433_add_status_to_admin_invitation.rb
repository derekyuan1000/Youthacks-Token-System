class AddStatusToAdminInvitation < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_invitations, :status, :string
  end
end

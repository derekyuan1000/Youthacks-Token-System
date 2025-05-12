class AddPasswordDigestToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :password_digest, :string
  end
end

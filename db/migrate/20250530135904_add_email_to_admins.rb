class AddEmailToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :email, :string
    add_index :admins, :email, unique: true
  end
end

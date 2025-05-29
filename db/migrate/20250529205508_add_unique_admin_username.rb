class AddUniqueAdminUsername < ActiveRecord::Migration[8.0]
  def change
    add_index :admins, :name, unique: true
  end
end

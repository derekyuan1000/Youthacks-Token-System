class AddAdminIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :admin_id, :integer
  end
end

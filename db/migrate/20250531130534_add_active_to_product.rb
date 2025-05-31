class AddActiveToProduct < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :active, :boolean
  end
end

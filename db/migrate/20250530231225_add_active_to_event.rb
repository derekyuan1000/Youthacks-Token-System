class AddActiveToEvent < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :active, :boolean, default: true, null: false
  end
end
p
class AddNameColumnToEvent < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :name_column, :string
  end
end

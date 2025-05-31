class AddDateToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :date, :date
  end
end

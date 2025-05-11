class Decimaltoint < ActiveRecord::Migration[8.0]
  def change
    change_column :participants, :balance, :integer
  end
end

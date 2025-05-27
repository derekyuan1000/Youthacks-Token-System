class AddActiveToParticipant < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :active, :boolean
    change_column_default :participants, :active, from: nil, to: true
    change_column_default :participants, :balance, from: nil, to: 0
  end
end

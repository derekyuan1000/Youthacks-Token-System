class AddCheckInToParticipant < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :checked_in, :boolean
    change_column_default :participants, :checked_in, from: nil, to: false
    add_column :participants, :check_in_time, :datetime
  end
end

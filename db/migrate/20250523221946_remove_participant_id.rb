class RemoveParticipantId < ActiveRecord::Migration[8.0]
  def change
    remove_column :participants, :participant_id
  end
end

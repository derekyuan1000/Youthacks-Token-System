class AddParticipantIdToEvent < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :id_column, :string
  end
end

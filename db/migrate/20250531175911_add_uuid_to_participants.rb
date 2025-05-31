class AddUuidToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :uuid, :string
    remove_column :events, :name_column, :string
  end
end

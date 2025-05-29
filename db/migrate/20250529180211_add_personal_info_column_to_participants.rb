class AddPersonalInfoColumnToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :personal_info, :json
  end
end

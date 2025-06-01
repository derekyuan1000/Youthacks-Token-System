class SyncWithAirtableOptionForParticipantsAgain < ActiveRecord::Migration[8.0]
  def change
    change_column :participants, :sync_with_airtable, :boolean, default: false, null: false
  end
end

class SyncWithAirtableOptionForParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :sync_with_airtable, :boolean, default: true, null: false
  end
end

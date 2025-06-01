class FixSyncing < ActiveRecord::Migration[8.0]
  def change
    # Remove the old column if it exists
    remove_column :participants, :sync_with_airtable, :boolean if column_exists?(:participants, :sync_with_airtable)

    # Add the new column with the correct default value
    add_column :events, :sync_with_airtable, :boolean, default: false, null: false
  end
end

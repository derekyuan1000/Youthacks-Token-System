class MakeActivityPolymorphic < ActiveRecord::Migration[8.0]
  def change
    remove_column :activities, :participant_id, :bigint
    add_reference :activities, :subject, polymorphic: true, index: true
  end
end

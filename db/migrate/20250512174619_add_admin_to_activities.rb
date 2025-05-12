class AddAdminToActivities < ActiveRecord::Migration[8.0]
  def change
    add_reference :activities, :admin, null: false, foreign_key: true
  end
end

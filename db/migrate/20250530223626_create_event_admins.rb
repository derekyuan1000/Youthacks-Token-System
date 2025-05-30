class CreateEventAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :event_admins do |t|
      t.references :event, null: false, foreign_key: true
      t.references :admin, null: false, foreign_key: true

      t.timestamps
    end
  end
end

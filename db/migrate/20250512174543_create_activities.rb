class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :participant, null: false, foreign_key: true
      t.string :action
      t.json :metadata

      t.timestamps
    end
  end
end

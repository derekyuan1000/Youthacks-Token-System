class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.text :description
      t.references :manager, null:false, foreign_key: { to_table: :admins }


      t.string :airtable_api_key
      t.string :airtable_base_id
      t.string :airtable_table_name

      t.timestamps
    end
  end
end

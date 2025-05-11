class CreateParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :participants do |t|
      t.integer :participant_id
      t.string :name
      t.string :pronouns
      t.date :date_of_birth
      t.string :email
      t.integer :balance

      t.timestamps
    end
  end
end

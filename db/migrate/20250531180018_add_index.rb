class AddIndex < ActiveRecord::Migration[8.0]
  def change
     	add_index :participants, :uuid, unique: true
  end
end

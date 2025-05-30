class RemovePronouns < ActiveRecord::Migration[8.0]
  def change
    remove_column :participants, :pronouns, :string
  end
end

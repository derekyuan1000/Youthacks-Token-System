class Privateinformationfix < ActiveRecord::Migration[7.1]
  def change
    change_column :participants, :dietary, :string
    change_column :participants, :consent, :boolean, using: 'consent::boolean'
  end
end

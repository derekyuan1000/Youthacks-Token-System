class RemovePersonalInfo < ActiveRecord::Migration[8.0]
  def change
    remove_column :participants, :date_of_birth
    remove_column :participants, :email
    remove_column :participants, :full_name
    remove_column :participants, :address
    remove_column :participants, :phone
    remove_column :participants, :emergency_name
    remove_column :participants, :emergency_phone
    remove_column :participants, :consent
    remove_column :participants, :dietary
    remove_column :participants, :medical
  end
end

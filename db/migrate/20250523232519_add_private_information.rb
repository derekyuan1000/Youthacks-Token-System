class AddPrivateInformation < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :full_name, :string
    add_column :participants, :address, :string
    add_column :participants, :phone, :string
    add_column :participants, :emergency_name, :string
    add_column :participants, :emergency_phone, :string
    add_column :participants, :consent, :boolean
    add_column :participants, :dietary, :string
    add_column :participants, :medical, :string
  end
end

class FixIdColumns < ActiveRecord::Migration[8.0]
  def change
    # remove_column :participants, :id_column
    add_column :participants, :name_column, :string
  end
end

class Fixidnamecolumnagain < ActiveRecord::Migration[8.0]
	def change
		remove_column :events, :id_column, :string
		add_column :events, :name_column, :string
		remove_column :participants, :name_column, :string
	end
end

class TryGeneralizeDataTokenAgain < ActiveRecord::Migration[8.0]
  def change
    remove_column :data_tokens, :type, :string
    remove_column :data_tokens, :name, :string
    remove_column :data_tokens, :email, :string
    remove_column :data_tokens, :password, :string
    remove_column :data_tokens, :code, :string
    add_column :data_tokens, :data, :json
  end
end

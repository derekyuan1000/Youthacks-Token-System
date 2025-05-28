class ChangeActiveAgainAgain < ActiveRecord::Migration[8.0]
  def change
    change_column_default :participants, :active, from: nil, to: true
  end
end

class ChangeActiveAgain < ActiveRecord::Migration[8.0]
  def up
    change_column_default :participants, :active, from: nil, to: true
  end

  def down
    change_column_default :participants, :active, from: true, to: nil
  end

end

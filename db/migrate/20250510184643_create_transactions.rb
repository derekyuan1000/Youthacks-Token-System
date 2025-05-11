class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :price

      t.timestamps
    end
  end
end

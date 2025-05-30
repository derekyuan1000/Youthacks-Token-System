class AddEventIdToParticipantsProductsTransactionsActivities < ActiveRecord::Migration[8.0]
  def change
    add_reference :participants, :event, foreign_key: true
    add_reference :products, :event, foreign_key: true
    add_reference :transactions, :event, foreign_key: true
    add_reference :activities, :event, foreign_key: true
  end
end

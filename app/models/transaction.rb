class Transaction < ApplicationRecord
  has_many :activities, as: :subject

  belongs_to :participant
  belongs_to :product

  def self.create!(participant_id:, product_id:, price:, admin_id: nil)
    transaction = super(participant_id: participant_id, product_id: product_id, price: price)
    
    Activity.create!(
      subject_id: transaction.id,
      subject_type: "Transaction",
      action: "transaction_create",
      metadata: { participant_id: participant_id, product_id: product_id, price: price }.to_json,
      admin_id: admin_id
    )
    
    transaction
  end
end

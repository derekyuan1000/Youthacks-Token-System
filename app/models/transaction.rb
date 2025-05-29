class Transaction < ApplicationRecord
  has_many :activities, as: :subject

  belongs_to :participant
  belongs_to :product

  def self.create(participant_id:, product_id:, price:, admin_id: )
    puts admin_id, "wefqnowenfqweug fbowqetrvoqiwrvoqwerhtvpvfqwher"
    unless admin_id.present? and Admin.exists?(admin_id)
      raise "Admin ID is required and must be valid"
    end
    transaction = super(participant_id: participant_id, product_id: product_id, price: price, admin_id: admin_id)
    Activity.create!(
      subject: transaction,
      action: "transaction_create",
      metadata: { participant_id: participant_id, product_id: product_id, price: price }.to_json,
      admin_id: admin_id
    )
    
    transaction
  end
end

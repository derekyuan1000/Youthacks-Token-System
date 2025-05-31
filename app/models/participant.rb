require 'airtable'
require 'dotenv/load'

class Participant < ApplicationRecord
    scope :active, -> { where(active: true) }
    scope :present , -> { where(active:true, checked_in:true) }
	belongs_to :event
    attribute :active, :boolean, default: true
    attribute :balance, :integer, default: 0
    attribute :checked_in, :boolean, default: false
    has_many :activities, as: :subject


    def earn!(amount: 1, admin_id:)
        if amount <= 0
            raise "Amount must be greater than 0"
        end
        new_balance = balance + amount
        Activity.create!(
			subject: self,
            action: "earn",
            metadata: {amount:amount, old_balance: balance, new_balance:new_balance}.to_json,
            admin_id: admin_id,
			event_id: event_id
        )
        update!(balance: new_balance)
    end

    def set_balance!(amount, admin_id)
        Activity.create!(
          subject: self,
          action: "set_balance",
          metadata: { amount: amount, old_balance:balance, new_balance:amount}.to_json,
          admin_id: admin_id,
		  event_id: event_id
        )
        update!(balance: amount)
    end

    def buy!(product, admin_id)
      begin
        # Check if the product is available
        if product.quantity > 0
            # Check if the participant has enough balance
            if balance >= product.price
                # Deduct the product price from the participant's balance
                
                # Mark the product as sold
                product.update!(quantity: product.quantity - 1)
                
                transaction = Transaction.create(
                  participant_id: id,
                  product_id: product.id,
                  price: product.price,
                  admin_id: admin_id,
				  event_id: event_id
                )
                Activity.create!(
					subject: self,
					action: "buy",
					metadata: { product_id: product.id, price: product.price, transaction_id: transaction.id, old_balance:balance, new_balance:balance-product.price}.to_json,
					admin_id: admin_id,
					event_id: event_id
                )
                  
                update!(balance: balance - product.price)
                # Return success message
                { success: true, message: "Purchase successful!" }
            else
                # Return error message if not enough balance
                { success: false, message: "Not enough balance!" }
            end
        else
            # Return error message if product is not available
            { success: false, message: "Product not available!" }
        end
      rescue StandardError => e
        {success: false, message: "Error during purchase: #{e.message}"}
      end
    end
    
    def delete!(admin_id = nil)
      begin 
        raise "Admin ID is required to delete a participant" if admin_id.nil?

        Activity.create!(
			subject: self,
			action: "delete_participant",
			metadata: { old_balance: balance }.to_json,
			admin_id: admin_id
        )
        update!(active: false)  # Soft-delete instead of destroy
        { success: true, message: "Participant deleted successfully" }
      rescue StandardError => e
        { success: false, message: "Error deleting participant: #{e.message}" }
      end
    end

    def check_in(admin_id = nil)
      begin
        raise "Admin ID is required to check in a participant" if admin_id.nil?
        
        if checked_in
          raise "Participant is already checked in"
        end
        
        update!(checked_in: true)
        
        Activity.create!(
			subject: self,
          	action: "check_in",
          	metadata: { }.to_json,
          	admin_id: admin_id,
			event_id: event_id
        )
        
        { success: true, message: "Participant checked in successfully" }
      rescue StandardError => e
        { success: false, message: "Error checking in participant: #{e.message}" }
      end
    end

end

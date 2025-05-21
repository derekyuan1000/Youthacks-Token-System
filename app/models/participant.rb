require 'airtable'
require 'dotenv/load'



class Participant < ApplicationRecord
    def earn!(amount = 1)
        new_balance = balance + amount
        Activity.create!(
            participant_id: id,
            action: "earn",
            metadata: {amount:amount, old_balance: balance, new_balance:new_balance}.to_json,
            admin_id: @admin.id,
        )
        update!(balance: new_balance)
    end

    def set_balance!(amount)
        Activity.create!(
          participant_id: id,
          action: "set_balance",
          metadata: { amount: amount, old_balance:balance, new_balance:amount}.to_json,
          admin_id: @admin.id,
        )
        update!(balance: amount)
    end

    def buy!(product)
        # Check if the product is available
        if product.available?
            # Check if the participant has enough balance
            if balance >= product.price
                # Deduct the product price from the participant's balance
                
                # Mark the product as sold
                product.update!(quantity: product.quantity - 1)
                
                transaction = Transaction.create!(
                  participant_id: id,
                  product_id: product.id,
                  price: product.price,
                  admin_id: @admin.id
                )
                Activity.create!(
                  participant_id: id,
                  action: "buy",
                  metadata: { product_id: product.id, price: product.price, transaction_id: transaction.id, old_balance:balance, new_balance:balance-product.price}.to_json,
                  admin_id: @admin.id
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

    end
    
  def self.sync # With Airtable
    begin
        api_key = ENV['AIRTABLE_API_KEY']
        base_id = ENV['AIRTABLE_BASE_ID']
        table_name = 'participants'
      # Initialize Airtable client
      client = Airtable::Client.new(api_key)
      records = client.table(base_id, table_name).all
      if records.nil?
        raise "Invalid API key, base ID, table name, etc. Check env variables and internet connection."
        # Get all records from the Airtable table
      end
      # Sync each Airtable record with the local database
      records.each do |record|
        participant = record.fields

        if participant['attendee_preferred_name'].nil?
          participant['attendee_preferred_name'] = participant['attendee_first_name']
        end
        # Check if the participant exists in the local database
        existing_participant = Participant.find_by(participant_id: participant['participant_ID'])
        
        
        if existing_participant
          # If the participant exists, update their details
          existing_participant.update!(
            participant_id: participant['participant_ID'],
            name: participant['attendee_preferred_name'],
            pronouns: participant['pronouns'],
            date_of_birth: participant['date_of_birth'],
            email: participant['attendee_email']
            # balance = existing_participant.balance
          )
        else
          # If the participant doesn't exist, create a new entry
          Participant.create!(
            participant_id: participant['participant_ID'],
            name: participant['attendee_preferred_name'],
            pronouns: participant['pronouns'],
            date_of_birth: participant['date_of_birth'],
            email: participant['attendee_email'],
            balance: 0
          )
        end
      end
      puts "Success"
      # Return success message if sync was successful
      { success: true, message: "Success" }

    rescue StandardError => e
      puts "Error syncing: #{e.message}"
      # If any error occurs during sync, catch the exception and return an error message
      { success: false, message: "Error syncing: #{e.message}" }
    end
  end
end

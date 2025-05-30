class Event < ApplicationRecord
	belongs_to :manager, class_name: 'Admin'

	has_many :participants, dependent: :destroy
	has_many :products, dependent: :destroy
	has_many :transactions, dependent: :destroy
	has_many :activities, dependent: :destroy

	encrypts :airtable_api_key
	encrypts :airtable_base_id
	encrypts :airtable_table_name

	def self.sync # With Airtable
      begin
        # Initialize Airtable client
        client = Airtable::Client.new(airtable_api_key)
        table  = client.table(airtable_base_id, airtable_table_name)

        records = table.select()

        if records.nil?
          raise "Invalid API key, base ID, table name, etc. Check variables entered and internet connection."
          # Get all records from the Airtable table
        end
        # Sync each Airtable record with the local database
        records.each do |record|
          participant = record.fields

          if participant['attendee_preferred_name'].nil?
            participant['attendee_preferred_name'] = participant['attendee_first_name']
          end
          # Check if the participant exists in the local database
          existing_participant = participants.find_by(id: participant[id_column])
          
          
          if existing_participant
            # If the participant exists, update their details
            existing_participant.update!(
              name: participant['attendee_preferred_name'],
              pronouns: participant['pronouns'],
			  personal_info: participant.to_json,
			  
              # balance = existing_participant.balance
            )
          else
            # If the participant doesn't exist, create a new entry
            participants.create!(
              id: participant['signup_ID'],
              name: participant['attendee_preferred_name'],
              pronouns: participant['pronouns'],
			  personal_info: participant.to_json,
			  event_id: id
            )
          end
        end
        participants.active.each do |p|
			if records.none? { |r| r.fields['signup_ID'] == p.id }
				p.delete!(0)
			end 
        end
        # Return success message if sync was successful
        { success: true, message: "Success" }

      rescue StandardError => e
        # If any error occurs during sync, catch the exception and return an error message
        { success: false, message: "Error syncing: #{e.message}" }
      end
    end
end

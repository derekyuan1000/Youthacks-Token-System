require 'friendly_id'
class Event < ApplicationRecord
	extend FriendlyId

	has_and_belongs_to_many :admins, join_table: 'event_admins'

	friendly_id :name, use: :slugged

	belongs_to :manager, class_name: 'Admin'

	has_many :participants, dependent: :destroy
	has_many :products, dependent: :destroy
	has_many :transactions, dependent: :destroy
	has_many :activities, dependent: :destroy

  	has_many :activities, as: :subject

	encrypts :airtable_api_key
	encrypts :airtable_base_id


    def slug_candidates
        [
            :name,
            -> { "#{name}-#{SecureRandom.hex(2)}" }
        ]
    end

	def add_admin!(admin_id:)
		begin
			unless admin_id.present? and Admin.exists?(admin_id)
				raise "Admin ID is required and must be valid"
			end
			unless admins.exists?(admin_id) or manager_id == admin_id
				admins << Admin.find(admin_id)
				{ success: true, message: "Admin added successfully" }
			else
				{ success: false, message: "Admin already exists in this event" }
			end
		rescue => e
			{ success: false, message: "Error adding admin: #{e.message}" }
		end
	end

	def self.create(name:, description: "", airtable_api_key: nil, airtable_base_id: nil, airtable_table_name: nil, manager_id:)
		begin
			unless name.present?
				raise "Name cannot be blank"
			end
			unless manager_id.present? and Admin.exists?(manager_id)
				raise "Manager ID is required and must be valid"
			end
			event = create!(
				name: name,
				description: description,
				airtable_api_key: airtable_api_key,
				airtable_base_id: airtable_base_id,
				airtable_table_name: airtable_table_name,
				manager_id: manager_id
			)
			{ success: true, message: "Event created successfully", event: event }
		rescue => e
			{ success: false, message: "Error creating event: #{e.message}" }
		end
	end
	

	def sync # With Airtable
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

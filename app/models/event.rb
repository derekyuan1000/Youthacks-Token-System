class Event < ApplicationRecord
  belongs_to :manager, class_name: 'Admin'

  encrypts :airtable_api_key
  encrypts :airtable_base_id
  encrypts :airtable_table_name
end

class Event < ApplicationRecord
  belongs_to :manager, class_name: 'Admin'

  has_many :participants
  has_many :products
  has_many :transactions
  has_many :activities

  encrypts :airtable_api_key
  encrypts :airtable_base_id
  encrypts :airtable_table_name
end

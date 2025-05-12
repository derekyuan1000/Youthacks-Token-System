class Activity < ApplicationRecord
  belongs_to :participant
  belongs_to :admin

  validates :action, presence: true
end

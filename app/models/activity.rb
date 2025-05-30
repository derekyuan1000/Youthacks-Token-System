class Activity < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :admin
  belongs_to :event

  validates :action, presence: true
end

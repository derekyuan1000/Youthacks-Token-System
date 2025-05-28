class Activity < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :admin

  validates :action, presence: true
end

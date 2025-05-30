class EventAdmin < ApplicationRecord
  belongs_to :event
  belongs_to :admin
end

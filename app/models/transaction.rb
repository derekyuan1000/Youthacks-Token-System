class Transaction < ApplicationRecord
  belongs_to :participant
  belongs_to :product
end

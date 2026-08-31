class Goal < ApplicationRecord
  belongs_to :match
  belongs_to :player, optional: true
end

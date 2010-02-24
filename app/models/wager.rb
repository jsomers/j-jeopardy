class Wager < ActiveRecord::Base
  serialize :their_scores
  belongs_to :player
  belongs_to :question
end

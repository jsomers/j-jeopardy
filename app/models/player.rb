require "digest"
class Player < ActiveRecord::Base
  has_many :guesses
  
  def self.new_if_needed(addr)
    if (p = Player.find_by_email(addr))
    else
      p = Player.new(:email => addr)
      p.save
    end
    return p
  end
end
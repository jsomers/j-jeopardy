require "digest"
class Player < ActiveRecord::Base
  has_many :guesses
  has_many :wagers
  has_and_belongs_to_many :episodes
  
  def self.new_if_needed(addr)
    if (p = Player.find_by_email(addr))
    else
      p = Player.new(:email => addr)
      p.save
    end
    return p
  end
  
  def handle
    return self.email.split("@").first
  end
  
  def episodes_for_game(game_id)
    return self.episodes.select {|ep| ep.game_id == game_id}
  end
  
end
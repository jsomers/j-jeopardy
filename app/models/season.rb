class Season < ActiveRecord::Base
  def count_games
    self.n_games = Game.find_all_by_season(self.id).length
    self.save
  end
end

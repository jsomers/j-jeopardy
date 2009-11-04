class Question < ActiveRecord::Base
  belongs_to :game, :foreign_key => "game_id", :primary_key => "game_id";
  
  def my_category
    g = Game.find_by_game_id(self.game_id)
    single = g.categories.first(6)
    double = g.categories[6..-2]
    if self.coord.include? 'DJ'
      return double[self.coord.split(',')[1].to_i - 1]
    else
      return single[self.coord.split(',')[1].to_i - 1]
    end
  end
  
  def set_category
    self.category = self.my_category
    self.save
  end
end

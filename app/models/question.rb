class Question < ActiveRecord::Base
  belongs_to :game, :foreign_key => "game_id", :primary_key => "game_id";
  belongs_to :category
  
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
  
  def set_dd_value
    if self.value == "DD"
      row = self.coord.split(",")[-1].to_i
      if Date.parse(self.game.airdate) >= Date.parse("2001-11-26") # Values doubled
        if self.coord.include? "DJ"
          self.value = (400 * row).to_s
        else
          self.value = (200 * row).to_s
        end
      else
        if self.coord.include? "DJ"
          self.value = (200 * row).to_s
        else
          self.value = (100 * row).to_s
        end
      end
      self.save
    end
  end
end

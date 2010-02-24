class Question < ActiveRecord::Base
  belongs_to :game, :foreign_key => "game_id", :primary_key => "game_id";
  belongs_to :category;
  has_many :guesses;
  has_many :wagers;
  
  def my_category
    g = Game.find_by_game_id(self.game_id)
    single = g.categories.first(6)
    double = g.categories[6..-2]
    if self.coord.include? 'DJ'
      return Category.new_if_needed(double[self.coord.split(',')[1].to_i - 1])
    else
      return Category.new_if_needed(single[self.coord.split(',')[1].to_i - 1])
    end
  end
  
  def set_category
    c = self.my_category
    c.q_count += 1
    c.save
    self.category = c
    self.save
  end
end

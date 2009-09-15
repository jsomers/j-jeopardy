class Question < ActiveRecord::Base
  def my_category
    g = Game.find_by_game_id(self.game_id)
    single = CGI.unescapeHTML(g.categories).split('^')[1..6]
    double = CGI.unescapeHTML(g.categories).split('^')[7..-2]
    if self.coord.include? 'DJ'
      return double[self.coord.split(',')[1].to_i - 1]
    else
      return single[self.coord.split(',')[1].to_i - 1]
    end
  end
end
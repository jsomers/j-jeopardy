# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def time(len)
    spice = rand(50) / 100.0
    base = 0.29 * len + 1.2
    if len <= 7 then base += 1.5 end
    t = base + spice
    return [[1 + t.to_i, 10].min, ((t - t.to_i) * 10).to_i]
  end
  
  def p1
    @p1 ||= Player.find(Rails.cache.read(session[:chnl])[:players][0]).handle
    return @p1
  end
  
  def p2
    @p2 ||= Player.find(Rails.cache.read(session[:chnl])[:players][1]).handle
    return @p2
  end
  
  def p3
    return ""
    #return Player.find(Rails.cache.read(session[:chnl])[:players][2]).handle
  end
  
  def p1pts
    @p1pts ||= Rails.cache.read(session[:chnl])[:scores][0]
    return @p1pts
  end
  
  def p2pts
    @p2pts ||= Rails.cache.read(session[:chnl])[:scores][1]
    return @p2pts
  end
  
  def p3pts
    @p3pts ||= Rails.cache.read(session[:chnl])[:scores][2]
    return @p3pts
  end
  
  def games
    @games ||= Game.find(:all)
    return @games
  end
  
  def current_player
    return Player.find(Rails.cache.read(session[:chnl])[:current_player]).handle
  end
end

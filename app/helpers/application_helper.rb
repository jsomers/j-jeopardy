# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def time(len)
    spice = rand(50) / 100.0
    base = (session[:time_multiplier] || 0.29) * len + 1.2
    if len <= 7 then base += 1.5 end
    t = base + spice
    return [[1 + t.to_i, 10].min, ((t - t.to_i) * 10).to_i]
  end
  
  #def ep
  #  return Episode.find(session[:ep_id])
  #end
  
  def p1
    if (s = session[:players][0]) and (p = Player.find(s)) then return p end
  end
  
  def p2
    if (s = session[:players][1]) and (p = Player.find(s)) then return p end
  end
  
  def p3
    if (s = session[:players][2]) and (p = Player.find(s)) then return p end
  end
  
  def games
    @games ||= Game.find(:all)
    return @games
  end
end

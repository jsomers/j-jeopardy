# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  helper :all # include all helpers, all the time
  Game
  Question

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '19d764005754338b38ffc7293ba4e27d'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  def double?
    ep = Episode.find(session[:ep_id])
    questions = cache("questions-#{ep.game_id}") { Game.find_by_game_id(ep.game_id).questions }
    return ep.answered >= questions.select {|q| !q.coord.include? "DJ" and !(q.coord == "N/A")}.length
  end
  
  def final?
    ep = Episode.find(session[:ep_id])
    questions = cache("questions-#{ep.game_id}") { Game.find_by_game_id(ep.game_id).questions }
    return ep.answered >= (questions.select {|q| q.coord.include? "DJ" and !(q.coord == "N/A")}.length - 1) && double?
  end
  
  private
  def cache(key)
    unless output = CACHE.get(key)
      output = yield
      CACHE.set(key, output, 1.hour)
    end
    return output
  end
  
#  def ep
#    return Episode.find(session[:ep_id])
#  end
end

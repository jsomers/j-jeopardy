# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '19d764005754338b38ffc7293ba4e27d'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  def double?
    ep = Episode.find_by_key(session[:ep_key])
    debugger
    return ep.answered >= Game.find_by_game_id(ep.game_id).questions.select {|q| !q.coord.include? "DJ" and !(q.coord == "N/A")}.length
  end
  
  def final?
    ep = Episode.find_by_key(session[:ep_key])
    return ep.answered >= (Game.find_by_game_id(ep.game_id).questions.length - 1)
  end
  
#  def ep
#    return Episode.find_by_key(session[:ep_key])
#  end
end

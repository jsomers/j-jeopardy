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
    ct = 0
    for i in (0..5)
      for j in (0..4)
        ct += ep.single_table[i][j][3]
      end
    end
    return ct >= 30
  end
  
  def final?
    ep = Episode.find_by_key(session[:ep_key])
    ct = 0
    for i in (0..5)
      for j in (0..4)
        ct += ep.single_table[i][j][3]
      end
    end
    for i in (0..5)
      for j in (0..4)
        ct += ep.double_table[i][j][3]
      end
    end
    return ct >= 59
  end
  
#  def ep
#    return Episode.find_by_key(session[:ep_key])
#  end
end

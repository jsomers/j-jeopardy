class PlayerController < ApplicationController
  def new
    if request.post? and params[:player]
      @player = Player.new(params[:player])
      @player.save
      redirect_to '/play/start'
    end
  rescue
    flash[:notice] = "Something went wrong! Maybe your handle is taken."
  end
  
  def validate
    handle, password, plyr = params[:handle], params[:pass], params[:player].to_i
    p = Player.find_by_handle(handle)
    if p and p.password_matches?(password)
      session[:players][plyr - 1] = p.id.to_s
      render :text => handle + "<br/><br/>"
    else
      render :partial => "play/start_spot", :locals => {:player => plyr.to_s}
    end
  end
end

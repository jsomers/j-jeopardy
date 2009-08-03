class PlayerController < ApplicationController
  def new
    if request.post? and params[:player]
      pass = params[:player][:password]
      hndl = params[:player][:handle]
      if hndl.nil? or hndl.empty?
        flash[:alert] = "You've gotta enter a handle there, chief."
      elsif pass.nil? or pass.empty?
        flash[:alert] = "You've gotta enter a password there, chief."
      elsif Player.find_by_handle(hndl)
        flash[:alert] = "Looks like the handle <b>#{hndl}</b> has been taken by somebody else. What are the odds?"
      else
        @player = Player.new(params[:player])
        @player.save
        flash[:notice] = "Your account (<b>#{hndl}</b>) has been created successfully!"
        redirect_to '/play/start'
      end
    end
  end
  
  def validate
    handle, password, plyr = params[:handle], params[:pass], params[:player].to_i
    keys = {1 => 'A', 2 => 'B', 3 => 'P'}
    p = Player.find_by_handle(handle)
    if p and p.password_matches?(password) and !session[:players].include? p.id.to_s
      session[:players][plyr - 1] = p.id.to_s
      render :text => "<div style='margin-left: -30px; padding: 10px; border: 1px solid #eee; background: #ffffee; font-weight: bold;'>" + handle + " <span style='color: #999; font-size: 20px; font-weight: normal;'>(use the <strong>#{keys[plyr]}</strong> key to buzz in)</span></div><br/>"
    else
      render :partial => "play/start_spot", :locals => {:player => plyr.to_s, :failed => true}
    end
  end
end

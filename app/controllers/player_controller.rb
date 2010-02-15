class PlayerController < ApplicationController
  
  def new
    @page_title = "Jimbo Jeopardy! Sign up as a new player"
    @body_id = "new_player"
    @slick_input = true
    @no_script = true
    
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
        if (x = session[:players].index(nil))
          session[:players][x] = @player.id.to_s
        end
        flash[:notice] = "Great news, <strong>#{hndl}</strong>: your account has been created successfully!"
        redirect_to '/play/start'
      end
    end
  end
  
  def validate
    handle, password, plyr = params[:handle], params[:pass], params[:player].to_i
    keys = {1 => 'A', 2 => 'B', 3 => 'P'}
    p = Player.find_by_handle(handle)
    if p and (cp = params[:crypted_pass]) and cp == p.password
      render :partial => "validated", :locals => {:handle => handle, :key => keys[plyr], :rm => plyr - 1}
    elsif p and p.password_matches?(password) and !session[:players].include? p.id.to_s
      session[:players][plyr - 1] = p.id.to_s
      render :partial => "validated", :locals => {:handle => handle, :key => keys[plyr], :rm => plyr - 1}
    else
      render :partial => "play/start_spot", :locals => {:player => plyr.to_s, :failed => true}
    end
  end
  
  def remove
    i = params[:num]
    session[:players][i.to_i] = nil
    render :partial => "play/start_spot", :locals => {:player => (i.to_i + 1).to_s, :failed => false}
  end
  
  def quickstart
    p1 = Player.new(:handle => params[:p1], :password => "jeopardy", :temp => true)
    p2 = Player.new(:handle => params[:p2], :password => "jeopardy", :temp => true)
    p3 = Player.new(:handle => params[:p3], :password => "jeopardy", :temp => true)
    p1.save(false)
    p2.save(false)
    p3.save(false)
    session[:players] = [p1.id.to_s, p2.id.to_s, p3.id.to_s]
    render :text => "Players #{p1.id}, #{p2.id}, and #{p3.id} successfully created."
  end
end

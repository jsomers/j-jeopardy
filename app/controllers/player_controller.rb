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
  
  # {"bin_id" => [Player1, Player2], "bin_id2" => [Player4], ...}
  def match
    @no_script = true
    session[:multi] = true
    my_handle = session[:my_handle] = "guest" + (Player.count + 1).to_s # TODO: sweep old guest accounts.
    me = Player.new(:handle => my_handle, :password => "jeopardy")
    me.save
    # Put me in a bin. TODO: check bin fullness asynchronously once the page has loaded.
    bins = Rails.cache.read("bins")
    if (@bid = params[:bin_id]) # If one has been specified, choose that.
      @bin = bins[@bid]
      bins[@bid] = @bin.push(me.id)
      Rails.cache.write("bins", bins)
    else # Otherwise...
      if (avail = bins.to_a.select {|x| x[1].length < 3}) and !avail.empty? # If there *are* bins available, put me in the emptiest.
        raw_bin = avail.sort {|a, b| a[1].length <=> b[1].length}.first
        @bin = raw_bin[1].push(me.id)
        @bid = raw_bin[0]
        bins[@bid] = @bin
        Rails.cache.write("bins", bins)
      else # Or just start my own.
        @bid = Digest::MD5.hexdigest(me.handle + Time.new.to_s).first(10)
        @bin = [me.id]
        bins[@bid] = @bin
        Rails.cache.write("bins", bins)
      end
    end
  end

  def check_bin
    bin = Rails.cache.read("bins")[params[:bid]]
    render :json => bin.collect {|x| Player.find(x).handle}
  end
end

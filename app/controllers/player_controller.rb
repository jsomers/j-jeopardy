class PlayerController < ApplicationController
  def quickstart
    raw = [params[:em1], params[:em2], params[:em3]]
    invalids = []
    raw.each do |r|
      email = r[/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/]
      if !email
        if not r.include? "Player "
          invalids << r
          session[:players] << nil
        else
          session[:players] << nil
        end  
      else
        p = Player.new_if_needed(email)
        session[:players] << p.id
      end
    end
    if invalids.empty?
      render :text => "OK"
    else
      session[:players] = []
      render :text => invalids.collect {|i| "<strong>#{i}</strong>"}.join(", ")
    end
  end

end

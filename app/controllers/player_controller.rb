class PlayerController < ApplicationController
  def quickstart
    p1 = Player.new(:handle => params[:p1], :password => "jeopardy")
    p2 = Player.new(:handle => params[:p2], :password => "jeopardy")
    p3 = Player.new(:handle => params[:p3], :password => "jeopardy")
    p1.save(false)
    p2.save(false)
    p3.save(false)
    session[:players] = [p1.id.to_s, p2.id.to_s, p3.id.to_s]
    render :text => "Players #{p1.id}, #{p2.id}, and #{p3.id} successfully created."
  end
end

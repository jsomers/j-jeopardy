class EditController < ApplicationController
  def board
    @game = Game.find_by_game_id(params[:id])
    @single = CGI.unescapeHTML(@game.categories).split('^')[1..6]
    @double = CGI.unescapeHTML(@game.categories).split('^')[7..-2]
    @questions = Question.find_all_by_game_id(params[:id])
  end
  
  def update
    q = Question.find_by_id(params[:q_id])
    q.answer = params[:answer]
    q.question = params[:question]
    q.value = params[:value]
    q.save!
    @outcome = ' <font color="#33ff33" size=1>&#10003;</font>'
  end
end

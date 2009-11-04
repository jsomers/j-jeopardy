class EditController < ApplicationController
  def board
    @game = Game.find_by_game_id(params[:id])
    @single = @game.categories.first(6)
    @double = @game.categories[6..-2]
    @questions = @game.questions
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

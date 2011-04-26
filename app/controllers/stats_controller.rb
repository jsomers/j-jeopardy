class StatsController < ApplicationController
  
  def pairwise
    @no_script = true
    @slick_input = true
  end
  
  def pairwise_results
    p1 = Player.find_by_email(params[:player_1].strip)
    p2 = Player.find_by_email(params[:player_2].strip)
    if p1 and p2
      showdowns = (p1.episodes & p2.episodes)
      @results = parsed(showdowns, p1.email, p2.email)
    else
      if p1
        flash[:alert] = "Couldn't find player with e-mail <strong>#{params[:player_2]}</strong>"
      elsif p2
        flash[:alert] = "Couldn't find player with e-mail <strong>#{params[:player_1]}</strong>"
      else
        flash[:alert] = "Couldn't find players with either of those e-mail addresses"
      end
      redirect_to :action => :pairwise
    end
  end
  
  private
  
  def parsed(showdowns, p1, p2)
    episodes = []
    wins = {p1 => 0, p2 => 0}
    showdowns.each do |episode|
      sode = {:game_id => episode.game_id}
      if episode.players.length == 2
        pos = {episode.players[0].email => 0, episode.players[1].email => 2}
      elsif episode.players.length == 3
        pos = {episode.players[0].email => 0, episode.players[1].email => 1, episode.players[2].email => 2}
      end
      # Basic outcome stuff.
      scores = {p1 => episode.points[pos[p1]].to_i, p2 => episode.points[pos[p2]].to_i}
      if scores[p1] > scores[p2]
        sode[:winner] = p1
        sode[:loser] = p2
        wins[p1] += 1
      elsif scores[p2] > scores[p1]
        sode[:winner] = p2
        sode[:loser] = p1
        wins[p2] += 1
      else
        sode[:winner] = p1
        sode[:loser] = p1
      end
      sode[:pts_final] = scores
      # Number of questions each player got right and wrong
      # Negative points and positive points for each player
      # Scores after single jeopardy, double jeopardy, and final
      n_correct = {0 => 0, 1 => 0, 2 => 0}
      n_wrong = {0 => 0, 1 => 0, 2 => 0}
      pts_single = {0 => 0, 1 => 0, 2 => 0}
      pts_double = {0 => 0, 1 => 0, 2 => 0}
      for i in (1..6)
        for j in (1..5)
          begin single = episode.single_table[i][j] rescue next end
          begin double = episode.double_table[i][j] rescue next end
          begin single_question = Question.find(single[4]) rescue next end
          if single_question.value != "DD"
            (0..2).each do |i|
              if single[i] == 0
                n_wrong[i] += 1
                pts_single[i] -= single_question.value.to_i
              elsif single[i] == 1
                n_correct[i] += 1
                pts_single[i] += single_question.value.to_i
              end
            end
          end
          
          begin double_question = Question.find(double[4]) rescue next end
          if double_question.value != "DD"
            (0..2).each do |i|
              if double[i] == 0
                n_wrong[i] += 1
                pts_double[i] -= double_question.value.to_i
              elsif double[i] == 1
                n_correct[i] += 1
                pts_double[i] += double_question.value.to_i
              end
            end
          end
        end
      end
      
      sode[:pts_single] = {p1 => pts_single[pos[p1]], p2 => pts_single[pos[p2]]}
      sode[:pts_double] = {p1 => pts_double[pos[p1]], p2 => pts_double[pos[p2]]}
      sode[:n_correct] = {p1 => n_correct[pos[p1]], p2 => n_correct[pos[p2]]}
      sode[:n_wrong] = {p1 => n_wrong[pos[p1]], p2 => n_wrong[pos[p2]]}
      
      wagers = Game.find_by_game_id(episode.game_id).questions.select {|q| q.value == "DD"}.collect {|q| q.wagers}.flatten
      dds = wagers.select {|w| w.player and episode.players.include? w.player}.collect {|w| begin [w.player.email, w.my_score, w.amount, Guess.find_by_question_id_and_player_id(w.question_id, w.player.id).correct?] rescue nil end}.compact
      sode[:dds] = dds
      episodes << sode
    end
    return {:wins => wins.to_a, :episodes => episodes}
  end
end

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
      # Sort out which player is in which position
      if episode.players.length == 2
        pos = {episode.players[0].email => 0, episode.players[1].email => 2}
      elsif episode.players.length == 3
        pos = {episode.players[0].email => 0, episode.players[1].email => 1, episode.players[2].email => 2}
      end
      # Basic outcome.
      scores = {p1 => episode.points[pos[p1]].to_i, p2 => episode.points[pos[p2]].to_i}
      sode[:pts_final] = scores
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
      sode[:ep] = episode
      sode[:pos] = pos
      episodes << sode
    end
    return {:wins => wins.to_a, :episodes => episodes}
  end
end

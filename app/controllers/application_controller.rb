# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  helper :all # include all helpers, all the time
  Game
  Question

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '19d764005754338b38ffc7293ba4e27d'
  
  def double?
    ep = Episode.find(session[:ep_id])
    questions = cache("questions-#{ep.game_id}") { Game.find_by_game_id(ep.game_id).questions }
    return ep.answered >= questions.select {|q| !q.coord.include? "DJ" and !(q.coord == "N/A")}.length
  end
  
  def final?
    ep = Episode.find(session[:ep_id])
    questions = cache("questions-#{ep.game_id}") { Game.find_by_game_id(ep.game_id).questions }
    return ep.answered >= (questions.select {|q| q.coord.include? "DJ" and !(q.coord == "N/A")}.length - 1) && double?
  end
  
  def init_game
    session[:ct] = 0
    if !session[:players] or session[:players].empty?
      session[:players] = [nil, nil, nil]
    end
  end
  
  def init_episode
    session[:ep_id] = nil
    session[:current] = nil
    session[:players] = []
    session[:p1_key], session[:p2_key], session[:p3_key] = nil, nil, nil
    session[:p1_key_name], session[:p2_key_name], session[:p3_key_name] = nil, nil, nil
  end
  
  def wipe_ep
    session[:ep_id] = nil
    session[:current] = nil
  end
  
  def redirect_to_game_if_specified
    if session[:go_to_game]
      redirect_to "/play/board/#{session[:go_to_game]}"
    end
  end
  
  def reject_playerless_games
    if !session[:players] or session[:players].compact.length.zero?
      redirect_to "/play/quickstart"
      flash[:notice] = "<strong>At least one player</strong> has to be signed in before you can play!"
      return
    end
  end
  
  def execute_key_change(p1, p2, p3)
    session[:p1_key] = p1[1]
    session[:p2_key] = p2[1]
    session[:p3_key] = p3[1]
    session[:p1_key_name] = p1[0]
    session[:p2_key_name] = p2[0]
    session[:p3_key_name] = p3[0]
  end
  
  def bounce_to_start_page_if_no_players(gid)
    if !session[:players]
      session[:go_to_game] = gid
      redirect_to "/play/quickstart"
      flash[:notice] = "You'll have to <strong>sign in quickly</strong> before you can play! Type your e-mail address below:"
      return
    end
  end
  
  def create_episode_if_needed(gid)
    if session[:ep_id].nil?
      if session[:players].compact.length.zero?
        ep = Episode.create(:game_id => gid)
      else
        players = Player.find(session[:players].compact)
        eps_for_each = players.collect {|p| p.episodes_for_game(gid)}
        if (ep = eps_for_each.inject {|int, e| int & e}.first)
          # Do nothing
        else
          ep = players.first.episodes.create(:game_id => gid)
          (players - [players.first]).each {|p| p.episodes << ep}
        end
      end
      session[:ep_id] = ep.id
      session[:current] = session[:players].compact.rand
    end
  end
  
  def show_bots_inspect_page
    if !session[:ep_id]
      redirect_to "/inspect/question/#{params[:id]}"
      return
    end
  end
  
  def ignore_bots
    if !session[:ep_id]
      render :nothing => true
      return
    end
  end
  
  def bounce_bots
    if !session[:ep_id]
      redirect_to "/play/board/#{params[:id]}"
      return
    end
  end
  
  def handle_daily_doubles(q)
    if q.value == "DD"
      redirect_to '/play/dd/' + params[:id]
    end
  end
  
  def mark_progress(q, ep)
    coords = q.coord
    col = coords.split(',')[1].to_i - 1
    row = coords.split(',')[2].to_i - 1
    if (ep.single_table[col][row][4].zero? and ep.double_table[col][row][4].zero?) # First time here.
      ep.answered += 1
    end
    if coords.split(',')[0] == 'J'
      ep_single_table = Marshal.load(Marshal.dump(ep.single_table))
      ep_single_table[col][row][3] = 1
      ep_single_table[col][row][4] = q.id
      ep.single_table = ep_single_table
    else
      ep_double_table = Marshal.load(Marshal.dump(ep.double_table))
      ep_double_table[col][row][3] = 1
      ep_double_table[col][row][4] = q.id
      ep.double_table = ep_double_table
    end
    ep.save
  end
  
  def execute_score_change(ep)
    # Get parameters
    value = params[:value].to_i
    type = params[:type].to_i
    my_id = params[:my_id]
    player = my_id.split('-')[-1].to_i
    col = my_id.split('-')[0].gsub('DJ', '').to_i - 1
    row = my_id.split('-')[1].to_i - 1
    
    new_type = ((type + 1) % 3).to_i
    
    # Change the question outcome
    if my_id.include? 'DJ'
      ep_double_table = Marshal.load(Marshal.dump(ep.double_table))
      ep_double_table[col][row][player] = new_type
      ep.double_table = ep_double_table
    else
      ep_single_table = Marshal.load(Marshal.dump(ep.single_table))
      ep_single_table[col][row][player] = new_type
      ep.single_table = ep_single_table
    end
    
    # Build return string
    case type
      when 0 # incorrect -> correct
        delta = 2 * value
        char = '<font color="#33ff33">&#10003;</font>'
        session[:current] = session[:players][player] # update current player
      when 1 # correct -> neutral
        delta = -1 * value
        char = '<font color="white" size="1">&#9679;</font>'
      when 2 # neutral -> incorrect
        delta = -1 * value
        char = '<font color="red">&#10007;</font>'
    end
    
    ep_points = Marshal.load(Marshal.dump(ep.points))
    case player
      when 0
        ep_points[0] += delta
      when 1
        ep_points[1] += delta
      when 2
        ep_points[2] += delta
    end
    ep.points = ep_points
    ep.save
    
    return { :char => char, :my_id => my_id, :delta => delta.to_s, :player => player + 1, :current => (type == 0 ? "1" : "0"), :new_type => new_type.to_s }
  end
  
  def initiate_daily_double_wager(ep, wager, q)
    wager = params[:wager]
    me = session[:current]
    my_score = ep.points[session[:players].index(me)]
    ep_points = Marshal.load(Marshal.dump(ep.points))
    ep_points.delete_at(session[:players].index(me))
    Wager.create(
      :amount => wager.to_i,
      :my_score => my_score,
      :their_scores => ep_points,
      :player_id => me,
      :question_id => q.id
    )
  end
  
  def validation_for_question(the_question, ep, guess, player, value)
    answer = the_question.answer.gsub('\\', '')
    game_id = the_question.game_id
    if guess != ""
      Guess.create(
        :guess => guess, 
        :question_id => the_question.id, 
        :player_id => session[:players][player.to_i - 1]
      )
    end
    guess_words = guess.split(' ')
    coords = the_question.coord
    col = coords.split(',')[1].to_i - 1
    row = coords.split(',')[2].to_i - 1
    t = true
    for word in guess_words
      if !answer.downcase.include? word.downcase
        t = false
      end
    end
    font_color = (t ? '#33ff33' : 'red')
    ep_points = Marshal.load(Marshal.dump(ep.points))
    if player == '1'
      ep_points[0] += (t ? value.to_i : value.to_i * -1)
      p = session[:players][0]
    elsif player == '2'
      ep_points[1] += (t ? value.to_i : value.to_i * -1)
      p = session[:players][1]
    elsif player == '3'
      ep_points[2] += (t ? value.to_i : value.to_i * -1)
      p = session[:players][2]
    end
    ep.points = ep_points
    if coords.split(',')[0] == 'J'
      ep_single_table = Marshal.load(Marshal.dump(ep.single_table))
      ep_single_table[col][row][player.to_i - 1] = (t ? 1 : 0)
      ep.single_table = ep_single_table
    elsif coords.split(',')[0] == 'DJ' 
      ep_double_table = Marshal.load(Marshal.dump(ep.double_table))
      ep_double_table[col][row][player.to_i - 1] = (t ? 1 : 0)
      ep.double_table = ep_double_table
    end
    if t then session[:current] = p end

    answer_color = (t ? '#33ff33' : '#211eab')
    st = ''
    st += '<script type="text/javascript">seconds += 100; $(\'out\').style.borderColor="#211eab";</script>'
    st += '<b><font color="' + answer_color + '">' + answer + '</font></b><br/>'
    st += '<small>' + '<font color="' + font_color + '">' + '[' + (!p.nil? ? Player.find(p.to_i).handle : 'Player ' + player) + (t ? ' +' : ' -') + '$' + value.to_s + ']</font><br/>'
    if t
      st += '<a href="/play/board/' + game_id.to_s + '" style="color: white;">&lt;&lt; Go back</a>'
    else
      st += '<a href="?time=7" style="color: white;">Anyone else?</a> &nbsp; &nbsp;'
      st += '<a href="/play/board/' + game_id.to_s + '?answer=' + CGI.escapeHTML(answer) + '" style="color: white;">No, go back</a>'
    end
    ep.save
    return st
  end
  
  # Should refactor this, obviously.
  def dd_validation_for_question(the_question, ep, guess, value)
    answer = the_question.answer.gsub('\\', '')
    game_id = the_question.game_id
    if guess != ""
      Guess.create(
        :guess => guess, 
        :question_id => the_question.id, 
        :player_id => session[:current]
      )
    end
    guess_words = guess.split(' ')
    t = true
    for word in guess_words
      if !answer.downcase.include? word.downcase
        t = false
      end
    end
    ep_points = Marshal.load(Marshal.dump(ep.points))
    if session[:current] == session[:players][0]
      ep_points[0] += (t ? value.to_i : value.to_i * -1)
      p = session[:players][0]
    elsif session[:current] == session[:players][1]
      ep_points[1] += (t ? value.to_i : value.to_i * -1)
      p = session[:players][1]
    elsif session[:current] == session[:players][2]
      ep_points[2] += (t ? value.to_i : value.to_i * -1)
      p = session[:players][2]
    end
    ep.points = ep_points
    font_color = (t ? '#33ff33' : 'red')
    answer_color = (t ? '#33ff33' : 'red')
    st = ''
    st += '<b><font color="' + answer_color + '">' + answer + '</font></b><br/>'
    st += '<small>' + '<font color="' + font_color + '">' + '[' + (session[:current] ? Player.find(session[:current].to_i).handle : 'Player') + (t ? ' +' : ' -') + '$' + value.to_s + ']</font><br/>'
    st += '<a href="/play/board/' + game_id.to_s + '" style="color: white;">&lt;&lt; Go back</a>'
    ep.save
  end
  
  private
  def cache(key)
    unless output = CACHE.get(key)
      output = yield
      CACHE.set(key, output, 1.hour)
    end
    return output
  end
end

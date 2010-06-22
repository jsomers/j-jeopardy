class PlayController < ApplicationController
  require 'cgi'
  protect_from_forgery :except => [:load_season]
  
  def landing
    @page_title = "Jimbo Jeopardy! Play thousands of real Jeopardy games, free."
    @body_id = "landing"
    @no_script = true
  end
  
  def start
    @page_title = "Jimbo Jeopardy! Player sign-in"
    @body_id = "start"
    @slick_input = true
    
    session[:ct] = 0
    if !session[:players] or session[:players].empty?
      session[:players] = [nil, nil, nil]
    end
  end
  
  def quickstart
    @no_script = true
    session[:ep_id] = nil
    session[:current] = nil
    session[:players] = []
    session[:p1_key], session[:p2_key], session[:p3_key] = nil, nil, nil
    session[:p1_key_name], session[:p2_key_name], session[:p3_key_name] = nil, nil, nil
    @page_title = "Jimbo Jeopardy! Player names"
    @body_id = "start"
    @slick_input = true
  end
  
  def choose_game
    if session[:go_to_game]
      redirect_to "/play/board/#{session[:go_to_game]}"
    end
    session[:ep_id] = nil
    session[:current] = nil
    if !session[:players] or session[:players].compact.length == 0
      redirect_to "/play/quickstart"
      flash[:notice] = "<strong>At least one player</strong> has to be signed in before you can play!"
      return
    end
    @page_title = "Jimbo Jeopardy! Choose a game to play"
    @body_id = "choose_game"
    @no_script = true
    # Grab list of games
    @games = Game.find_all_by_season(26)
  end
  
  def change_keys
    debugger
    render :layout => false
  end
  
  def commit_key_change
    p1, p2, p3 = params[:p1].split("-"), params[:p2].split("-"), params[:p3].split("-")
    session[:p1_key] = p1[1]
    session[:p2_key] = p2[1]
    session[:p3_key] = p3[1]
    session[:p1_key_name] = p1[0]
    session[:p2_key_name] = p2[0]
    session[:p3_key_name] = p3[0]
    render :text => "OK"
  end
  
  def commit_timer_change
    session[:time_multiplier] = params[:new_time].to_f
    render :text => "OK"
  end
  
  def board
    session[:go_to_game] = nil
    @no_script = true
    @game_id = params[:id].to_i
    if !session[:players]
      session[:go_to_game] = @game_id
      redirect_to "/play/quickstart"
      flash[:notice] = "You'll have to <strong>sign in quickly</strong> before you can play! Type your e-mail address below:"
      return
    end
    if session[:ep_id].nil?
      if session[:players].compact.length.zero?
        ep = Episode.create(:game_id => @game_id)
      else
        players = Player.find(session[:players].compact)
        eps_for_each = players.collect {|p| p.episodes_for_game(@game_id)}
        if (ep = eps_for_each.inject {|int, e| int & e}.first)
          # Do nothing
        else
          ep = players.first.episodes.create(:game_id => @game_id)
          (players - [players.first]).each {|p| p.episodes << ep}
        end
      end
      session[:ep_id] = ep.id
      session[:current] = session[:players].compact.rand
    end
    @game_id = params[:id]
    @game = Game.find_by_game_id(@game_id)
    @doubled = Date.parse(@game.airdate) >= Date.parse("2001-11-26")
    @page_title = "Jimbo Jeopardy! Game #{@game.game_id} (#{@game.airdate})"
    @body_id = "board"
    
    @single = @game.categories.first(6)
    @double = @game.categories[6..-2]
    
    @finished = double?
    @final = final?
    
    @questions = cache("questions_#{@game.game_id}") { map = {}; @game.questions.each {|q| map[q.coord] = q.id}; map }
    @chars = ['<font color="red">&#10007;</font>', '<font color="#33ff33">&#10003;</font>', '<font color="white" size="1">&#9679;</font>']
  end
  
  def question
    if !session[:ep_id]
      redirect_to "/inspect/question/#{params[:id]}"
      return
    end
    ep = Episode.find(session[:ep_id])
    @q = Question.find(params[:id])
    @page_title = "$#{@q.value} | #{@q.category.name}"
    @body_id = "question"
    if @q.value == "DD"
      redirect_to '/play/dd/' + params[:id]
    end
    coords = @q.coord
    col = coords.split(',')[1].to_i - 1
    row = coords.split(',')[2].to_i - 1
    if (ep.single_table[col][row][4].zero? and ep.double_table[col][row][4].zero?) # First time here.
      ep.answered += 1
    end
    if coords.split(',')[0] == 'J'
      ep_single_table = Marshal.load(Marshal.dump(ep.single_table))
      ep_single_table[col][row][3] = 1
      ep_single_table[col][row][4] = @q.id
      ep.single_table = ep_single_table
    else
      ep_double_table = Marshal.load(Marshal.dump(ep.double_table))
      ep_double_table[col][row][3] = 1
      ep_double_table[col][row][4] = @q.id
      ep.double_table = ep_double_table
    end
    ep.save
  end
  
  def change_scores
    if !session[:ep_id]
      render :nothing => true
      return
    end
    ep = Episode.find(session[:ep_id])
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
    
    render :json => { :char => char, :my_id => my_id, :delta => delta.to_s, :player => player + 1, :current => (type == 0 ? "1" : "0"), :new_type => new_type.to_s}
  end
  
  def dd
    @page_title = "Daily Double!"
    @body_id = "dd"
  end
  
  def daily_double
    if !session[:ep_id]
      redirect_to "/inspect/question/#{params[:q_id]}"
      return
    end
    @q = Question.find_by_id(params[:q_id])
    @wager = params[:wager]
    ep = Episode.find(session[:ep_id])
    me = session[:current]
    my_score = ep.points[session[:players].index(me)]
    ep_points = Marshal.load(Marshal.dump(ep.points))
    ep_points.delete_at(session[:players].index(me))
    Wager.create(
      :amount => @wager.to_i,
      :my_score => my_score,
      :their_scores => ep_points,
      :player_id => me,
      :question_id => @q.id
    )
    @page_title = "Daily Double in #{@q.category.name} for $#{@wager}"
    @body_id = "question"
  end
  
  def search
  end
  
  def find_questions
    a = Time.new
    ct = 0
    query = params[:query].downcase
    words = query.split(' ')
    garbage = ['this', 'the', 'a', 'an', 'of', 'in', 'about', 'to', 'from', 'am', 'as']
    garbage.each {|g| words.delete(g) { words }}
    if !words.nil? and !words.empty?
      @questions = Question.find(:all, :conditions => ["question like '%%" + words[0] + "%%' or answer like '%%" + words[0] + "%%'"], :limit => 3000)
    else
      @results = 'Try using less common search terms.'
      return
    end
    if words.length > 1
      for word in words[1..-1]
        @questions = @questions.select { |q| q.question.downcase.include? word or q.answer.downcase.include? word }
      end
    end
    returned = "<ul style='list-style:none;'>"
    for q in @questions
      ct += 1
      begin
        returned += '<li>' + q.question + ' (<span id="answer' + q.id.to_s + '" style="display:none;">' + q.answer + '</span><a href="#show" id="reveal' + q.id.to_s + '" onclick="reveal(' + q.id.to_s + ');">answer</a>) <small>(<font color="#aaaaaa">$' + q.value.to_s + ', ' + Game.find_by_game_id(q.game_id).airdate + '</font>)</small> </li><br/>'
      rescue
      end
    end
    returned += '</li></ul><br/>'
    @results = '<small>' + ct.to_s + ' results took ' + (Time.new - a).to_s + ' seconds.</small>' + returned
  end
  
  def wager
    if !session[:ep_id]
      redirect_to "/play/board/#{params[:id]}"
      return
    end
    @q = Question.find_by_game_id(params[:id], :conditions => ['value = "N/A"'])
    @category = Game.find_by_game_id(params[:id]).categories.last
    @page_title = "Final Jeopardy! (#{@category})"
    @body_id = "question"
  end
  
  def final_jeopardy
    @q = Question.find_by_id(params[:q_id])
    @answer = @q.answer
    @wager1 = params[:wager_1]
    @wager2 = params[:wager_2]
    @wager3 = params[:wager_3]
    @page_title = "Final Jeopardy!"
    @body_id = "question"
  end
  
  def validate
    ep = Episode.find(session[:ep_id])
    guess = params[:answer]
    player = params[:player]
    value = params[:value]
    the_question = Question.find_by_id(params[:question_id])
    answer = the_question.answer.gsub('\\', '')
    game_id = the_question.game_id
    if guess != ""
      Guess.create(
        :guess => guess, 
        :question_id => the_question.id, 
        :player_id => session[:players][params[:player].to_i - 1]
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
    @outcome = st
  end
  
  def validate_dd
    ep = Episode.find(session[:ep_id])
    guess = params[:answer]
    value = params[:wager]
    the_question = Question.find_by_id(params[:question_id])
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
    @outcome = st
  end
  
  def game_over
    @page_title = "Game over!"
    @body_id = "question"
    ep = Episode.find(session[:ep_id])
    the_question = Question.find_by_id(params[:q_id])
    
    @guess1 = params[:guess_1]
    @guess2 = params[:guess_2]
    @guess3 = params[:guess_3]
    guesses = [@guess1, @guess2, @guess3]
    guesses.each_with_index do |gue, i|
      if gue != ""
        Guess.create(
          :guess => gue, 
          :question_id => the_question.id,
          :player_id => session[:players][i]
        )
      end
    end
    
    @wager1 = params[:wager_1]
    @wager2 = params[:wager_2]
    @wager3 = params[:wager_3]
    wagers = [@wager1, @wager2, @wager3]
    wagers.each_with_index do |wag, i|
      the_ep_points = Marshal.load(Marshal.dump(ep.points))
      my_score = the_ep_points[i]
      the_ep_points.delete_at(i)
      Wager.create(
        :amount => wag.to_i,
        :question_id => the_question.id,
        :player_id => session[:players][i],
        :my_score => my_score,
        :their_scores => the_ep_points
      )
    end
    
    answer = the_question.answer
    game_id = the_question.game_id
    guess1_words = @guess1.split(' ')
    guess2_words = @guess2.split(' ')
    guess3_words = @guess3.split(' ')
    
    t1 = true
    for word in guess1_words
      if !answer.downcase.include? word.downcase
        t1 = false
      end
    end
    t2 = true
    for word in guess2_words
      if !answer.downcase.include? word.downcase
        t2 = false
      end
    end
    t3 = true
    for word in guess3_words
      if !answer.downcase.include? word.downcase
        t3 = false
      end
    end
    ep_points = Marshal.load(Marshal.dump(ep.points))
    ep_points[0] += (t1 ? @wager1.to_i : @wager1.to_i * -1)
    ep_points[1] += (t2 ? @wager2.to_i : @wager2.to_i * -1)
    ep_points[2] += (t3 ? @wager3.to_i : @wager3.to_i * -1)
    ep.points = ep_points
    ep.save
    @answer = answer
    
  end
  
  def load_season
    ret = {}
    ret[:content] = render_to_string :partial => "season", :locals => {:n => params[:season_number].to_i}
    ret[:season_n] = params[:season_number].to_i
    render :json => ret
  end
  
  def info
    @page_title = "Jimbo Jeopardy! How-to"
    @body_id = "info"
    @no_script = true
  end
  
end
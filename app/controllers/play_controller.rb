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
  
  def choose_game
    @page_title = "Jimbo Jeopardy! Choose a game to play"
    @body_id = "choose_game"
    @no_script = true
    if session[:players].compact.length < 2
      flash[:alert] = "<strong>At least two players</strong> must be signed in before you can play."
      redirect_to "/play/start"
    else
      # Grab list of games
      @games = Game.find_all_by_season(26)
    end
  end
  
  def board
    if (old_ep = Episode.find_all_by_game_id(params[:id]).select {|e| (e.key.split('_')[0..2].reject {|x| x == '0'} & session[:players].reject {|y| y.nil?}).length == session[:players].reject {|y| y.nil?}.length}.first)
      ep_key = old_ep.key
      session[:players] = old_ep.key.split('_')[0..2].collect {|x| if x == '0' then nil else x end}
      ep = old_ep
    else
      ep_key = session[:players].collect {|p| p.to_i}.join('_') + '_' + params[:id]
      ep = Episode.find_by_key(ep_key)
    end
    if ep
      session[:ep_key] = ep_key
      ep_charts = ep.charts.dclone
      ep_charts[0] << ep.points[0]
      ep_charts[1] << ep.points[1]
      ep_charts[2] << ep.points[2]
      ep.charts = ep_charts
      ep.save
      @finished = double?
      @final = final?
    else
      points = [0, 0, 0]
      session[:current] = session[:players].rand
      charts = [[], [], []]
      single_table = []
      for i in (1..6)
        a = []
        for j in (1..5)
          a << [2, 2, 2, 0, 0]
        end
        single_table << a
      end
      double_table = []
      for i in (1..6)
        a = []
        for j in (1..5)
          a << [2, 2, 2, 0, 0]
        end
        double_table << a
      end
      new_ep = Episode.new(:key => ep_key, :game_id => params[:id].to_i, :answered => 0, :single_table => single_table, :double_table => double_table, :points => points, :charts => charts)
      new_ep.save
      session[:ep_key] = ep_key
      @finished = false
      @final = false
    end
    @game = Game.find_by_game_id(params[:id].to_i)
    @page_title = "Jeopardy! Game #{@game.game_id} (#{@game.airdate})"
    @body_id = "board"
    
    @single = @game.categories.first(6)
    @double = @game.categories[6..-2]
    
    if !(@questions = CACHE.get("questions-#{params[:id]}"))
      @questions = @game.questions.collect {|q| [q.id, q.value, q.coord]}
      CACHE.set("questions-#{params[:id]}", @questions, 45.minutes)
    end

    @chars = ['<font color="red">&#10007;</font>', '<font color="#33ff33">&#10003;</font>', '<font color="white" size="1">&#9679;</font>']
  end
  
  def question
    ep = Episode.find_by_key(session[:ep_key])
    @q = Question.find(params[:id])
    @page_title = "$#{@q.value} | #{@q.category.name}"
    @body_id = "question"
    if @q.value.include? 'DD'
      redirect_to '/play/dd/' + params[:id]
    end
    coords = @q.coord
    col = coords.split(',')[1].to_i - 1
    row = coords.split(',')[2].to_i - 1
    if (ep.single_table[col][row][4].zero? and ep.double_table[col][row][4].zero?) # First time here.
      ep.answered += 1
    end
    if coords.split(',')[0] == 'J'
      ep_single_table = ep.single_table.dclone
      ep_single_table[col][row][3] = 1
      ep_single_table[col][row][4] = @q.id
      ep.single_table = ep_single_table
    else
      ep_double_table = ep.double_table.dclone
      ep_double_table[col][row][3] = 1
      ep_double_table[col][row][4] = @q.id
      ep.double_table = ep_double_table
    end
    ep.save
  end
  
  def change_scores
    ep = Episode.find_by_key(session[:ep_key])
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
      ep_double_table = ep.double_table.dclone
      ep_double_table[col][row][player] = new_type
      ep.double_table = ep_double_table
    else
      ep_single_table = ep.single_table.dclone
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
    
    ep_points = ep.points.dclone
    case player
      when 0
        ep_points[0] += delta
      when 1
        ep_points[1] += delta
      when 2
        ep_points[2] += delta
    end
    ep.points = ep_points
    st = '<script type="text/javascript">'
    st += 'upd(' + delta.to_s + ', ' + (player + 1).to_s + ', ' + (type == 0 ? '1' : '0') + ');'
    st += '</script>'
    st += '<a style="text-decoration:none;" href="#" onclick="'
    st += 'new Ajax.Updater(\'' + my_id + '\', \'/play/change_scores?'
    st += 'my_id=' + my_id + '&value=' + value.to_s + '&type=' + (new_type).to_s + '\', ' 
    st += '{asynchronous:true, evalScripts:true, parameters:\''
    st += 'authenticity_token=\' + encodeURIComponent(\'' + params[:authenticity_token] + '\')}); '
    st += 'return false;">'
    st += char + '</a>'
    ep.save
    render :text => st
  end
  
  def dd
    @page_title = "Daily Double!"
    @body_id = "dd"
  end
  
  def daily_double
    @q = Question.find_by_id(params[:q_id])
    @wager = params[:wager]
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
    @q = Question.find_by_game_id(params[:id], :conditions => ['fj = ?', true])
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
    ep = Episode.find_by_key(session[:ep_key])
    guess = params[:answer]
    player = params[:player]
    value = params[:value]
    the_question = Question.find_by_id(params[:question_id])
    answer = the_question.answer.gsub('\\', '')
    game_id = the_question.game_id
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
    ep_points = ep.points.dclone
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
      ep_single_table = ep.single_table.dclone
      ep_single_table[col][row][player.to_i - 1] = (t ? 1 : 0)
      ep.single_table = ep_single_table
    elsif coords.split(',')[0] == 'DJ' 
      ep_double_table = ep.double_table.dclone
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
    ep = Episode.find_by_key(session[:ep_key])
    guess = params[:answer]
    value = params[:wager]
    the_question = Question.find_by_id(params[:question_id])
    answer = the_question.answer.gsub('\\', '')
    game_id = the_question.game_id
    guess_words = guess.split(' ')
    t = true
    for word in guess_words
      if !answer.downcase.include? word.downcase
        t = false
      end
    end
    ep_points = ep.points.dclone
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
    st += '<small>' + '<font color="' + font_color + '">' + '[' + ((pl = Player.find(session[:current].to_i)) ? pl.handle : 'Player') + (t ? ' +' : ' -') + '$' + value.to_s + ']</font><br/>'
    st += '<a href="/play/board/' + game_id.to_s + '" style="color: white;">&lt;&lt; Go back</a>'
    ep.save
    @outcome = st
  end
  
  def validate_blast
    guess = params[:answer]
    q = Question.find_by_id(params[:question_id])
    value = params[:value]
    if guess.empty?
      @outcome = '(' + q.answer.gsub('\\', '') + ')<script type="text/javascript">window.location.href=window.location.href</script>'
    else
      t = true
      for word in guess.split(' ')
        if !q.answer.gsub('\\', '').downcase.include? word.downcase
          t = false
        end
      end
      if t
        @outcome = '<font color="#33ff33">&#10003; (' + q.answer.gsub('\\', '') + ')</font><script type="text/javascript">window.location.href=window.location.href</script>'
      else
        @outcome = '<font color="red">&#10007; (' + q.answer.gsub('\\', '') + ')</font><script type="text/javascript">window.location.href=window.location.href</script>'
      end
    end
  end
  
  def game_over
    @page_title = "Game over!"
    @body_id = "question"
    ep = Episode.find_by_key(session[:ep_key])
    @guess1 = params[:guess_1]
    @guess2 = params[:guess_2]
    @guess3 = params[:guess_3]
    
    @wager1 = params[:wager_1]
    @wager2 = params[:wager_2]
    @wager3 = params[:wager_3]
    
    the_question = Question.find_by_id(params[:q_id])
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
    ep_points = ep.points.dclone
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
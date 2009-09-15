class PlayController < ApplicationController
  require 'cgi'
  protect_from_forgery :except => [:load_season, :buzz]
  before_filter :preload_models
  
  def preload_models
    Question
    Game
    Player
  end
  
  def landing
    @page_title = "Jimbo Jeopardy! Play nearly every Jeopardy game ever aired, free."
    @body_id = "landing"
    @no_script = true
  end
  
  def start
    @page_title = "Jimbo Jeopardy! Player sign-in"
    @body_id = "start"
    @slick_input = true
    
    my_handle = "guest " + (Player.count + 1).to_s # TODO: sweep old guest accounts. TODO: allow already-signed in users.
    me = Player.new(:handle => my_handle, :password => "jeopardy")
    me.save
    session[:me] = me.id
    session[:chnl] = params[:game]
    
    session[:ct] = 0
    if !session[:players] or session[:players].empty?
      session[:players] = [nil, nil, nil]
    end
  end
  
  def blast
    @q = Question.find_all_by_category("word origins", :limit => 1, :order => :random)[0]
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
      @games = Game.find(:all, :conditions => 'season = 25')
    end
  end
  
  def board
    @game_id = params[:id]
    @game = Game.find_by_game_id(@game_id)
    @page_title = "Jeopardy! Game #{@game.game_id} (#{@game.airdate})"
    @body_id = "board"
    
    @single = CGI.unescapeHTML(@game.categories).split('^')[1..6]
    @double = CGI.unescapeHTML(@game.categories).split('^')[7..-2]

    #@questions = Rails.cache.fetch("questions_for_game_#{@game_id}") do
    #  Question.find(:all, :conditions => 'game_id = ' + @game_id)
    #end
    @questions = Question.find(:all, :conditions => 'game_id = ' + @game_id)
    
    @chars = ['<font color="red">&#10007;</font>', '<font color="#33ff33">&#10003;</font>', '<font color="white" size="1">&#9679;</font>']
  end
  
  def question
    @q = Question.find(params[:id])
    @page_title = "$#{@q.value} | #{@q.my_category}"
    @body_id = "question"
    if @q.value == 'DD'
      redirect_to '/play/dd/' + params[:id]
    end
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
    @page_title = "Daily Double in #{@q.category} for $#{@wager}"
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
    @category = Game.find_by_game_id(params[:id]).categories.split('^')[-1]
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
  
  def buzz
    tt = params[:tt].to_i
    player_handle = params[:id]
    while true
      cp = Rails.cache.read(session[:ep_key])
      time_bin = cp[:time_bin]
      if time_bin.nil? or time_bin.empty?
        cp[:time_bin] = [[tt, player_handle]]
        Rails.cache.write(session[:ep_key], cp)
        sleep(2)
        redo
      else
        if !time_bin.collect {|x| x[1]}.include? player_handle # If I'm not in there
          time_bin << [tt, player_handle]
        end
        winner_handle = time_bin.sort.first[1]
        if session[:my_handle] == winner_handle and !cp[:winner]
          cp[:winner] = true
          Rails.cache.write(session[:ep_key], cp)
          render :text => "win"
          return
        else
          render :text => "lose"
          return
        end
      end
    end
  end
  
  def validate
    qid = params[:question_id]
    guess = params[:answer]
    value = params[:value]
    seen_at = params[:seen_at]
    submit_time = params[:submit_time]
    the_question = Question.find(qid)
    answer = the_question.answer.gsub('\\', '')
    game_id = the_question.game_id
    guess_words = guess.split(' ')
    thresh = (answer.length < 5 ? answer.length : [(answer.length / 2).to_i + 1, 5].max)
    ct = 0
    t = true
    for word in guess_words
      if !answer.downcase.include? word.downcase
        t = false
      else
        ct += word.length
      end
    end
    if guess.strip.empty? then t = false end
    if ct >= thresh then t = true else t = false end
    cp = Rails.cache.read(session[:chnl])
    if cp[:answer_pit].nil? then cp[:answer_pit] = [[submit_time.to_i - seen_at.to_i, session[:me], t]] else cp[:answer_pit] << [submit_time.to_i - seen_at.to_i, session[:me], t] end
    Rails.cache.write(session[:chnl], cp)
    if cp[:answer_pit].length >= 2
      rights, wrongs = cp[:answer_pit].partition {|x| x[2]}
      
      Juggernaut.send_to_channel("winner('" + winner + "', " + qid + ")", session[:chnl])
      Juggernaut.send_to_client("active(true)", winner);
      Juggernaut.send_to_clients("active(false)", Rails.cache.read(session[:chnl])[:players] - [winner])
    end
    st = "<strong>#{guess}</strong> is " + (t ? "correct" : "incorrect") + ". "
    if !t then st += "The correct answer is <span style='color: #33ff33'>" + answer + "</span>" end
    st += "<div style='color: white; font-size: 11px;'>(It took you <strong>#{(submit_time.to_i - seen_at.to_i) / 1000.to_f}</strong> seconds to answer.)</div>"
    render :text => "<div style='color: " + (t ? "#33ff33" : "red") + "; font-size: 14px; margin-bottom: 0px; line-height: 20px;'>" + st + "</div>"
    # Collect answers and tts.
    # Determine outcome.
    # Pick the winner. (Render the results)
    # Change scores appropriately.
    # Assign the correct current player.
    # Wipe out the answered question, replace it with corrector icons.
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
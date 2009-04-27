class PlayController < ApplicationController
  require 'cgi'  
  
  def blast
    $start_time = Time.new
    $score = 0
    @q = Question.find_all_by_value('200', :limit => 1, :order => :random)[0]
  end
  
  def start
    $ct = 0
  end
  
  def choose_game
    # Initialization
    $p1, $p2, $p3 = params[:p1], params[:p2], params[:p3]
    $p1pts, $p2pts, $p3pts = 0, 0, 0
    $current = [$p1, $p2, $p3].rand
    $p1chart, $p2chart, $p3chart = [], [], []
    $single_table = []
    for i in (1..6)
      a = []
      for j in (1..5)
        a << [2, 2, 2, 0, 0]
      end
      $single_table << a
    end
    $double_table = []
    for i in (1..6)
      a = []
      for j in (1..5)
        a << [2, 2, 2, 0, 0]
      end
      $double_table << a
    end
    
    # Grab list of games
    @games = Game.find(:all)

  end
  
  def board
    $p1chart << $p1pts unless $p1pts < 0
    $p2chart << $p2pts unless $p2pts < 0
    $p3chart << $p3pts unless $p3pts < 0
    @game_id = params[:id]
    @game = Game.find_by_game_id(@game_id)
    
    @single = CGI.unescapeHTML(@game.categories).split('^')[1..6]
    @double = CGI.unescapeHTML(@game.categories).split('^')[7..-2]
    
    @questions = Question.find(:all, :conditions => 'game_id = ' + @game_id)
    @finished = double?
    @final = final?
    
    @chars = ['<font color="red">&#10007;</font>', '<font color="#33ff33">&#10003;</font>', '<font color="white" size="1">&#9679;</font>']
  end
  
  def question
    @q = Question.find_by_id(params[:id])
    if @q.value == 'DD'
      redirect_to '/play/dd/' + params[:id]
    end
    coords = @q.coord
    col = coords.split(',')[1].to_i - 1
    row = coords.split(',')[2].to_i - 1
    if coords.split(',')[0] == 'J'
      $single_table[col][row][3] = 1
      $single_table[col][row][4] = @q.id
    else
      $double_table[col][row][3] = 1
      $double_table[col][row][4] = @q.id
    end
  end
  
  def change_scores
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
      $double_table[col][row][player] = new_type
    else
      $single_table[col][row][player] = new_type
    end
    
    # Build return string
    case type
      when 0 # incorrect -> correct
        delta = 2 * value
        char = '<font color="#33ff33">&#10003;</font>'
        $current = [$p1, $p2, $p3][player] # update current player
      when 1 # correct -> neutral
        delta = -1 * value
        char = '<font color="white" size="1">&#9679;</font>'
      when 2 # neutral -> incorrect
        delta = -1 * value
        char = '<font color="red">&#10007;</font>'
    end
    
    case player
      when 0
        $p1pts += delta
      when 1
        $p2pts += delta
      when 2
        $p3pts += delta
    end
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
    render :text => st
  end
  
  def dd
    
  end
  
  def daily_double
    @q = Question.find_by_id(params[:q_id])
    @wager = params[:wager]
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
  end
  
  def final_jeopardy
    @q = Question.find_by_id(params[:q_id])
    @answer = @q.answer
    @wager1 = params[:wager_1]
    @wager2 = params[:wager_2]
    @wager3 = params[:wager_3]
  end
  
  def validate
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
    if player == '1'
      $p1pts += (t ? value.to_i : value.to_i * -1)
      p = $p1
    elsif player == '2'
      $p2pts += (t ? value.to_i : value.to_i * -1)
      p = $p2
    elsif player == '3'
      $p3pts += (t ? value.to_i : value.to_i * -1)
      p = $p3
    end
    if coords.split(',')[0] == 'J'
      $single_table[col][row][player.to_i - 1] = (t ? 1 : 0)
    elsif coords.split(',')[0] == 'DJ'                                                          
      $double_table[col][row][player.to_i - 1] = (t ? 1 : 0)
    end
    if t then $current = p end

    answer_color = (t ? '#33ff33' : '#211eab')
    st = ''
    st += '<script type="text/javascript">seconds += 100; $(\'out\').style.borderColor="#211eab";</script>'
    st += '<b><font color="' + answer_color + '">' + answer + '</font></b><br/>'
    st += '<small>' + '<font color="' + font_color + '">' + '[' + p + (t ? ' +' : ' -') + '$' + value.to_s + ']</font><br/>'
    if t
      st += '<a href="/play/board/' + game_id.to_s + '" style="color: white;">&lt;&lt; Go back</a>'
    else
      st += '<a href="?time=7" style="color: white;">Anyone else?</a> &nbsp; &nbsp;'
      st += '<a href="/play/board/' + game_id.to_s + '?answer=' + CGI.escapeHTML(answer) + '" style="color: white;">No, go back</a>'
    end
    @outcome = st
  end
  
  def validate_dd
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
    if $current == $p1
      $p1pts += (t ? value.to_i : value.to_i * -1)
      p = $p1
    elsif $current == $p2
      $p2pts += (t ? value.to_i : value.to_i * -1)
      p = $p2
    elsif $current == $p3
      $p3pts += (t ? value.to_i : value.to_i * -1)
      p = $p3
    end
    font_color = (t ? '#33ff33' : 'red')
    answer_color = (t ? '#33ff33' : 'red')
    st = ''
    st += '<b><font color="' + answer_color + '">' + answer + '</font></b><br/>'
    st += '<small>' + '<font color="' + font_color + '">' + '[' + $current + (t ? ' +' : ' -') + '$' + value.to_s + ']</font><br/>'
    st += '<a href="/play/board/' + game_id.to_s + '" style="color: white;">&lt;&lt; Go back</a>'
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
    
    $p1pts += (t1 ? @wager1.to_i : @wager1.to_i * -1)
    $p2pts += (t2 ? @wager2.to_i : @wager2.to_i * -1)
    $p3pts += (t3 ? @wager3.to_i : @wager3.to_i * -1)
    @answer = answer
    
  end
  
end

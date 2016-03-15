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
    
    init_game
  end
  
  def quickstart
    @page_title = "Jimbo Jeopardy! Player names"
    @body_id = "start"
    @no_script = true
    @slick_input = true
    
    init_episode
  end
  
  def choose_game
    @page_title = "Jimbo Jeopardy! Choose a game to play"
    @body_id = "choose_game"
    @no_script = true
    @games = Game.find_all_by_season(32)
    @max_season = Season.all.collect(&:id).max

    redirect_to_game_if_specified
    reject_playerless_games
  end
  
  def change_keys
    render :layout => false
  end
  
  def commit_key_change
    p1, p2, p3 = params[:p1].split("-"), params[:p2].split("-"), params[:p3].split("-")
    execute_key_change(p1, p2, p3)
    render :text => "OK"
  end
  
  def commit_timer_change
    session[:time_multiplier] = params[:new_time].to_f
    render :text => "OK"
  end
  
  def board
    @game_id = params[:id].to_i
    @game = Game.find_by_game_id(@game_id)
    @page_title = "Jimbo Jeopardy! Game #{@game_id} (#{@game.airdate})"
    @body_id = "board"
    @no_script = true
    session[:go_to_game] = nil
    
    bounce_to_start_page_if_no_players(@game_id)
    create_episode_if_needed(@game_id)
    
    # Question values were increased in late 2001.
    @doubled = Date.parse(@game.airdate) >= Date.parse("2001-11-26")
    
    @single = @game.categories.first(6)
    @double = @game.categories[6..-2]
    @finished = double?
    @final = final?
    @questions = cache("questions_#{@game.game_id}") { map = {}; @game.questions.each {|q| map[q.coord] = q.id}; map }
    @chars = ['<font color="red">&#10007;</font>', '<font color="#33ff33">&#10003;</font>', '<font color="white" size="1">&#9679;</font>']
  end
  
  def question
    @q = Question.find(params[:id])
    @page_title = "$#{@q.value} | #{@q.category.name}"
    @body_id = "question"
    ep = Episode.find(session[:ep_id])
    
    show_bots_inspect_page
    handle_daily_doubles(@q)
    mark_progress(@q, ep)
  end
  
  def change_scores
    ep = Episode.find(session[:ep_id])
    
    ignore_bots
    render :json => execute_score_change(ep)
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
    ep = Episode.find(session[:ep_id])
    
    show_bots_inspect_page
    initiate_daily_double_wager(ep, @wager, @q)
  end
  
  def search
  end
  
  def find_questions
    a = Time.new
    questions = Question.find_all_using_search_terms(params[:query].downcase)
    if questions
      @results = '<small>' + questions.length.to_s + ' results took ' + (Time.new - a).to_s + ' seconds.</small>' + Question.html_for_questions(questions)
    else
      @results = "Try using less common search terms"
    end
  end
  
  def wager
    @q = Question.find_by_game_id(params[:id], :conditions => ['value = "N/A"'])
    @category = Game.find_by_game_id(params[:id]).categories.last
    @page_title = "Final Jeopardy! (#{@category})"
    @body_id = "question"
    
    bounce_bots
  end
  
  def final_jeopardy
    @q = Question.find_by_id(params[:q_id])
    @answer = @q.answer
    @wager1 = params[:wager_1].gsub(/[^\d]/, '')
    @wager2 = params[:wager_2].gsub(/[^\d]/, '')
    @wager3 = params[:wager_3].gsub(/[^\d]/, '')
    @page_title = "Final Jeopardy!"
    @body_id = "question"
  end
  
  def validate
    ep = Episode.find(session[:ep_id])
    q = Question.find_by_id(params[:question_id])
    @outcome = validation_for_question(q, ep, params[:answer], params[:player], params[:value])
  end
  
  def validate_dd
    ep = Episode.find(session[:ep_id])
    q = Question.find_by_id(params[:question_id])
    @outcome = dd_validation_for_question(q, ep, params[:answer], params[:wager].gsub(/[^\d]/, ''))
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
    
    @wager1 = params[:wager_1].gsub(/[^\d]/, '')
    @wager2 = params[:wager_2].gsub(/[^\d]/, '')
    @wager3 = params[:wager_3].gsub(/[^\d]/, '')
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
  
  def change_current_player_directly
    session[:current] = session[:players][params[:choice].to_i - 1]
    render :text => "OK"
  end
end
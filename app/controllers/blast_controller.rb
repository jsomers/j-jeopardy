class BlastController < ApplicationController
  protect_from_forgery :except => [:get_categories]
  
  def constraints
    render :layout => false
  end
  
  def get_categories
    query = params[:q].strip.upcase
    words = query.split(' ').sort {|a, b| b.length <=> a.length}
    if words.nil? or words.empty?
      @categories = []
    else
      garbage = ['THIS', 'THE', 'A', 'AN', 'OF', 'IN', 'ABOUT', 'TO', 'FROM', 'AM', 'AS']
      garbage.each {|g| words.delete(g) { words }}
      @categories = cache("categories") { Category.find(:all).collect {|c| [c.name, c.q_count, c.id]} }
      @categories = @categories.select {|c| begin c[0].include? words[0] rescue false end}
      if words.length > 1
        for word in words[1..-1]
          @categories = @categories.select {|c| c[0].include? word}
        end
      end
      @categories =  @categories.collect {|cat| "#{cat[0]},#{cat[1]},#{cat[2]}"}
    end
    render :layout => false
  end
  
  def play
    @no_script = true
    @body_id = "question"
    if request.post? and (em = params[:email_address][/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/])
      p = Player.new_if_needed(em)
      p.save
      session[:p_id] = p.id
    elsif request.post?
      flash[:alert] = "You need to enter a <strong>valid e-mail address</strong> (step 5) before playing. Please try again."
      redirect_to "/blast"
      return
    end
    if (questionset_id = params[:game_id])
      @question_ids = Questionset.find(questionset_id.to_i).q_ids
      @game_id = questionset_id
      if (params[:p_id])
        session[:p_id] = params[:p_id]
      end
    else
      if params[:finals]
        # We should respect the season parameters and search terms,
        # but throw out categories and values.
        @final = true
        @questions = Question.find_all_by_value("N/A")
      end
      season_min = params[:season_min].to_i
      season_max = params[:season_max].to_i
      value_min = params[:value_min].to_i
      value_max = params[:value_max].to_i
      category_ids = params[:category_ids].split(",").collect {|id| id.strip.to_i}
      search_terms = params[:search_terms].split(",").collect {|term| term.strip.downcase}.sort {|a, b| b.length <=> a.length}
      
      unless params[:finals]
        @questions = refine_by_categories(category_ids)
      end
      search_results = refine_by_search_terms(@questions, search_terms)
      @questions = search_results[0]
      flag = search_results[1]
      if !flag
        @questions = refine_by_seasons(@questions, season_min, season_max)
        unless params[:finals]
          @questions = refine_by_values(@questions, value_min, value_max)
        end
      end
      @question_ids = @questions.sort_by { rand }.collect {|q| q.id.to_s}.join(",")
      if @question_ids.empty?
        flash[:alert] = "We couldn't find any questions using the criteria you specified. Try a broader search."
        redirect_to "/blast"
      end
      qs = Questionset.new_if_needed(@question_ids)
      qs.save
      @game_id = qs.id
    end
  end
  
  def fetch_question
    @q = Question.find(params[:q_id].to_i)
    render :json => {:category => @q.category.name, :answer => @q.answer, :question => @q.question, :value => @q.value}
  end
  
  def log_guess
    pid = (params[:p_id] ? params[:p_id].to_i : nil)
    g = Guess.new(
      :guess => params[:guess], 
      :question_id => params[:q_id].to_i, 
      :player_id => pid,
      :source => "blast")
    g.save
    render :nothing => true
  end
  
  def game_over
    @no_script = true
    @time = params[:time]
    @score = params[:score]
    @stumpers = Question.find(params[:stumpers].split(",").collect {|x| x.to_i})
    @ignorants = Question.find(params[:ignorants].split(",").collect {|x| x.to_i})
    @p_id = session[:p_id] || params[:p_id]
    if @score.index("-")
      color = "red"
    else
      color = "#33ff33"
    end
    @final_score = "<span style=\"color:#{color};\">$#{@score}</span>"
    @game_id = params[:game_id]
    @body_id = "question"
  end
  
  private
  
  def refine_by_categories(category_ids)
    return Category.find(category_ids).collect {|c| c.questions}.flatten
  end
  
  def refine_by_search_terms(questions, search_terms)
    flag = false
    if !search_terms.empty?
      garbage = ['this', 'the', 'a', 'an', 'of', 'in', 'about', 'to', 'from', 'am', 'as']
      garbage.each {|g| search_terms.delete(g) { search_terms }}
      if questions.empty?
        questions = Question.find(
          :all, 
          :conditions => ["question like \"%%" + search_terms[0] + "%%\" or answer like \"%%" + search_terms[0] + "%%\""], 
          :limit => 3000
        )
      end
      search_terms.each do |search_term|
        questions = questions.select { |q| q.question.downcase.include? search_term or q.answer.downcase.include? search_term }
      end
      if questions.empty? then flag = true end
    end
    return [questions, flag]
  end
  
  def refine_by_seasons(questions, season_min, season_max)
    if questions.empty?
      questions = Game.find(
        :all, 
        :conditions => ["season >= ? and season <= ?", season_min, season_max],
        :limit => 10,
        :order => :random
      ).collect {|g| g.questions}.flatten
    else
      questions = questions.select {|q| q.game.season >= season_min && q.game.season <= season_max}
    end
    return questions
  end
  
  def refine_by_values(questions, value_min, value_max)
    return questions.reject {|q| q.value == "N/A" or q.value == "DD" or q.value.to_i < value_min or q.value.to_i > value_max}.first(500)
  end
end

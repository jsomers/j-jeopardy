class BlastController < ApplicationController
  protect_from_forgery :except => [:get_categories]
  
  def constraints
    render :layout => false
  end
  
  def get_categories
    query = params[:q].upcase
    words = query.split(' ').sort {|a, b| b.length <=> a.length}
    garbage = ['THIS', 'THE', 'A', 'AN', 'OF', 'IN', 'ABOUT', 'TO', 'FROM', 'AM', 'AS']
    garbage.each {|g| words.delete(g) { words }}
    @categories = Rails.cache.read("cats").select {|c| begin c[0].include? words[0] rescue false end}
    if words.length > 1
      for word in words[1..-1]
        @categories = @categories.select {|c| c[0].include? word}
      end
    end
    @categories =  @categories.collect {|cat| "#{cat[0]},#{cat[1]},#{cat[2]}"}
    render :layout => false
  end
  
  def play
    season_min = params[:season_min].to_i
    season_max = params[:season_max].to_i
    value_min = params[:value_min].to_i
    value_max = params[:value_max].to_i
    category_ids = params[:category_ids].split(",").collect {|id| id.strip.to_i}
    search_terms = params[:search_terms].split(",").collect {|term| term.strip.downcase}.sort {|a, b| b.length <=> a.length}
    
    @questions = refine_by_categories(category_ids)
    @questions = refine_by_search_terms(@questions, search_terms)
    @questions = refine_by_seasons(@questions, season_min, season_max)
    @questions = refine_by_values(@questions, value_min, value_max)
    @question_ids = @questions.collect {|q| q.id.to_s}.join(",")
    @no_script = true
    @body_id = "question"
  end
  
  def fetch_question
    @q = Question.find(params[:q_id].to_i)
    render :json => {:category => @q.category.name, :answer => @q.answer, :question => @q.question, :value => @q.value}
  end
  
  private
  
  def refine_by_categories(category_ids)
    return Category.find(category_ids).collect {|c| c.questions}.flatten
  end
  
  def refine_by_search_terms(questions, search_terms)
    if !search_terms.empty?
      garbage = ['this', 'the', 'a', 'an', 'of', 'in', 'about', 'to', 'from', 'am', 'as']
      garbage.each {|g| search_terms.delete(g) { search_terms }}
      if questions.empty?
        questions = Question.find(
          :all, 
          :conditions => ["question like '%%" + search_terms[0] + "%%' or answer like '%%" + search_terms[0] + "%%'"], 
          :limit => 3000
        )
      end
      search_terms.each do |search_term|
        questions = questions.select { |q| q.question.downcase.include? search_term or q.answer.downcase.include? search_term }
      end
    end
    return questions
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
    if questions.empty?
      questions = Question.find(
        :all,
        :order => :random,
        :limit => 200
      ).reject {|q| q.value == "N/A" or q.value == "DD" or q.value.to_i < value_min or q.value.to_i > value_max}
    else
      questions = questions.reject {|q| q.value == "N/A" or q.value == "DD" or q.value.to_i < value_min or q.value.to_i > value_max}
    end
    return questions
  end
end

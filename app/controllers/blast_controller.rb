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
    cats_done, seasons_done, values_done, searches_done = false, false, false, false
    season_min = params[:season_min].to_i
    season_max = params[:season_max].to_i
    value_min = params[:value_min].to_i
    value_max = params[:value_max].to_i
    categories = params[:category_ids].split(",").collect {|id| id.strip.to_i}
    search_terms = params[:search_terms].split(",").collect {|term| term.strip.downcase}
    garbage = ['this', 'the', 'a', 'an', 'of', 'in', 'about', 'to', 'from', 'am', 'as']
    garbage.each {|g| search_terms.delete(g) { search_terms }}
    if categories
      questions = Category.find(category_ids).collect {|c| c.questions}.flatten
      cats = true
    elsif search_terms
      questions = Question.find(:all, :conditions => ["question like '%%" + search_terms[0] + "%%' or answer like '%%" + search_terms[0] + "%%'"], :limit => 3000)
      searches = true
    elsif 
      
    end
  end
  
  private
  
  def refine_by_terms(questions, search_terms)
    if search_terms.length > 1
      for search_term in search_terms[1..-1]
        questions = questions.select { |q| q.question.downcase.include? search_term or q.answer.downcase.include? search_term }
      end
    end
    return questions
  end
end

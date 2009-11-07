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
    @categories =  @categories.collect {|cat| "#{cat[0]},#{cat[1]}"}
    render :layout => false
  end
  
  def play
    render :layout => false
  end
end

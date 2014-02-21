class Question < ActiveRecord::Base
  belongs_to :game, :foreign_key => "game_id", :primary_key => "game_id";
  belongs_to :category;
  has_many :guesses;
  has_many :wagers;
  
  def my_category
    g = Game.find_by_game_id(self.game_id)
    single = g.categories.first(6)
    double = g.categories[6..-2]
    if self.coord.include? 'DJ'
      return Category.new_if_needed(double[self.coord.split(',')[1].to_i - 1])
    else
      return Category.new_if_needed(single[self.coord.split(',')[1].to_i - 1])
    end
  end
  
  def set_category
    c = self.my_category
    c.q_count += 1
    c.save
    self.category = c
    self.save
  end
  
  def self.find_all_using_search_terms(query)
    words = query.split(' ')
    garbage = ['this', 'the', 'a', 'an', 'of', 'in', 'about', 'to', 'from', 'am', 'as']
    garbage.each {|g| words.delete(g) { words }}
    if !words.nil? and !words.empty?
      questions = self.find(:all, :conditions => ["question like '%%" + words[0] + "%%' or answer like '%%" + words[0] + "%%'"], :limit => 3000)
    else
      questions = nil
    end
    if questions
      if words.length > 1
        for word in words[1..-1]
          questions = questions.select { |q| q.question.downcase.include? word or q.answer.downcase.include? word }
        end
      end
    end
    return questions
  end
  
  def self.html_for_questions(questions)
    returned = "<ul style='list-style:none;'>"
    for q in questions
      begin
        returned += '<li>' + q.question + ' (<span id="answer' + q.id.to_s + '" style="display:none;">' + q.answer + '</span><a href="#show" id="reveal' + q.id.to_s + '" onclick="reveal(' + q.id.to_s + ');">answer</a>) <small>(<font color="#aaaaaa">$' + q.value.to_s + ', ' + Game.find_by_game_id(q.game_id).airdate + '</font>)</small> </li><br/>'
      rescue
      end
    end
    returned += '</li></ul><br/>'
  end
  
  def first_image
    question.scan(/href="(.*?)"/).flatten.detect {|a| mime = Rehoster::MIME_TYPES[a.split(".").last]; mime && mime.include?('image')}
  end
  
  def caption
    question.scan(/\(.*?<a.*?href="#{first_image}".*?>(.*?)<\/a>\)/).flatten.first
  end
  
  def question_without_caption
    question.gsub(/\(.*?<a.*?href="#{first_image}".*?>(.*?)<\/a>\)/, "").strip
  end
  
  def rehost_media!
    (Hpricot(question)/"a").each do |a|
      next unless a['href'].include?('media')
      
      rehosted_url = Rehoster.rehost(a['href'])
      next unless rehosted_url.present?
      
      self.question = question.gsub(a['href'], rehosted_url)
    end
    save! if question_changed?
  end
end
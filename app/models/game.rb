class Game < ActiveRecord::Base
  has_many :questions, :primary_key => "game_id";
  has_many :players;
  has_many :episodes;
  
  serialize :categories;
  
  after_create :set_question_categories
  
  def self.add_season(n)
    for game_id in Dir.entries('/users/jsomers/Desktop/season ' + n.to_s + '/')[2..-1]
      puts game_id
      test = File.new('/users/jsomers/Desktop/season ' + n.to_s + '/' + game_id, 'r').readlines
      for i in (0..test.length - 1)
        if test[i].include? 'Show #'
          show_name = test[i]
        end
      end
      begin
        airdate = show_name.split(' ')[-1]
        categories = ''
        for i in (2..15)
          categories += '^' + test[i].strip!
        end
    
        g = Game.new(:game_id => game_id.gsub('.txt', ''), :categories => categories, :airdate => airdate, :season => n)
        g.save!

       for i in (0..test.length - 1)
         if test[i].include? 'J,' and test[i].strip.length == 5 or test[i].strip.length == 6
           coord = test[i]
           value = test[i + 1]
           question = test[i + 2]
           answer = test[i + 3]
           begin
             answer = answer.sub('&quot;&gt;', '').gsub('&lt;', '').gsub('&gt;', '').gsub('/em', '')
             q = Question.new(:game_id => game_id.gsub('.txt', ''), :coord => coord.strip, :value => value.strip, :question => question.strip, :answer => answer.strip)
             q.save!
           rescue
             puts 'question failed'
           end
         end
       end
     rescue
       puts 'game failed'
     end
    end
  end
  
  def self.add_final_jeopardies(n)
    for game_id in Dir.entries('/users/jsomers/Desktop/season ' + n.to_s + '/')[2..-1]
      puts game_id
      begin
        f = File.new('/users/jsomers/Desktop/season ' + n.to_s + '/' + game_id, 'r').readlines
        fj_answer = f[0]
        fj_question = f[1]
        q = Question.new(:game_id => game_id.gsub('.txt', ''), :coord => 'N/A', :value => 'N/A', :question => fj_question.strip, :answer => fj_answer.strip, :fj => 1)
        q.save!
      rescue
        puts 'failed'
      end
    end
  end
  
  def self.add_metadata
    f = File.new("#{RAILS_ROOT}/parse/metadata.txt", "r").readlines
#    mes = []
    for line in f
      game_id = line.split(' ')[0]
      metadata = line.split(' ')[1..-1].join(' ')
      g = Game.find_by_game_id(game_id)
#      mes << metadata.chomp.gsub(".", "")
      begin
        g.metadata = metadata.chomp.gsub(".", "")
        g.save!
      rescue
      end
    end
#    return mes
  end
  
  def self.add_categories
    qs = Question.find(:all)
    qs.each { |q|
      begin
        puts q.id
        q.category = q.my_category.downcase
        q.save!
      rescue
        p "failed"
      end
    }
  end
  
  def check_completeness
    game = Game.find_by_game_id(self.game_id)
    questions = Question.find_all_by_game_id(self.game_id)
    for j in (1..5)
      for i in (1..6)
        qJ = questions.select {|q| q.coord == 'DJ,' + i.to_s + ',' + j.to_s}[0]
        if qJ.nil? or qJ.question == '' then return false end
      end
    end
    return true
  end
  
  def played?(players)
    my_eps = Episode.find_all_by_game_id(self.game_id)
    return my_eps.select {|ep| !(ep.key.split('_')[0..2].reject {|x| x == '0'} & players.reject {|y| y.nil?}).empty? and ep.answered >= 59}.length > 0
  end
  
  def in_progress?(players)
    my_eps = Episode.find_all_by_game_id(self.game_id)
    return my_eps.select {|ep| (ep.key.split('_')[0..2].reject {|x| x == '0'} & players.reject {|y| y.nil?}).length == players.reject {|y| y.nil?}.length and ep.answered >= 5}.length > 0
  end
  
  def set_question_categories
    self.questions.each do |q|
      q.set_category
    end
  end

end

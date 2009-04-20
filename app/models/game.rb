class Game < ActiveRecord::Base
  has_many :questions;
  has_many :players;
  
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
end

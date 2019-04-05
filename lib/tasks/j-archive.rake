require 'open-uri'
require 'htmlentities'
require 'hpricot'
Hpricot.buffer_size = 262144 # http://justsoftwareconsulting.com/blog/?p=123

namespace :fetch do
  def doc(url)
    return open(url) {|f| Hpricot(f)}
  end
  
  def clean(str)
    return HTMLEntities.new.decode(str).gsub("\\", "")
  end
  
  task :games => :environment do
    # For each season, grab the list of game URLs:
    game_urls_to_get = {}
    (1..35).each do |season|
      puts "Checking season #{season} for new games..."
      season_page = doc("http://j-archive.com/showseason.php?season=#{season}")
      games_we_have_for_this_season = Game.find_all_by_season(season).collect(&:game_id)
      (season_page/"a").each do |a|
        if (href = a.attributes["href"]).include? "showgame.php" # If it's a game link...
          if not (games_we_have_for_this_season.include? href.split("game_id=")[-1].to_i) # ...and we don't have it
            if game_urls_to_get[season]
              game_urls_to_get[season] << href
            else
              game_urls_to_get[season] = [href]
            end
          end
        end
      end
      if game_urls_to_get[season]
        puts "  #{game_urls_to_get[season].length} found.\n"
      end
    end
    
    game_urls_to_get.each_pair do |season, game_urls|
      puts "\n\n---------------------------------------"
      puts "     FETCHING #{game_urls.length} GAMES IN SEASON #{season}."
      puts "---------------------------------------\n\n"
      game_urls.each do |game_url|
        game_id = game_url.split("game_id=")[-1].to_i
        puts "Fetching clues for game #{game_id}..."
        begin
        # Edge cases...
          if !game_url.include? "j-archive.com" then game_url = "http://www.j-archive.com/" + game_url end
          if Game.find_by_game_id(game_id)
            puts "  already have it?"
            next
          end
          game_page = doc(game_url)
          game_params = {}
          game_params[:categories] = (game_page/"td.category_name").collect {|td| clean(td.inner_html)}
          game_params[:airdate] = (game_page/"title").inner_html.split(" aired ")[-1]
          game_params[:game_id] = game_id
          game_params[:season] = season

          (game_page/"td.clue").each do |clue|
            clue = Hpricot(clue.inner_html)
            clue_params = {}
            clue_params[:game_id] = game_params[:game_id]
          
            # Get the question's value:
            if !(dd = (clue/"td.clue_value_daily_double").inner_html).strip.empty?
              clue_params[:value] = "DD"
            elsif !(val = (clue/"td.clue_value").inner_html).strip.empty?
              clue_params[:value] = val.gsub("$", "")
            elsif (fj = (clue/"#clue_FJ")) and !fj.inner_html.strip.empty?
              clue_params[:question] = clean(fj.inner_html)
              clue_params[:coord] = "N/A"
              clue_params[:value] = "N/A"
              clue_params[:fj] = fj
              final_table = Hpricot((game_page/"table.final_round").first.inner_html)
              answer = Hpricot(clean((final_table/"div").first.attributes["onmouseover"]))
              clue_params[:answer] = clean((answer/"em.correct_response").inner_html)
              q = Question.new(clue_params)
              q.save
              next
            else # This is an empty question. Move on.
              next
            end
            # Get the question and coord:
            clue_params[:question] = clean((clue/"td.clue_text").inner_html)
            clue_params[:coord] = (clue/"td.clue_text").first.attributes["id"].split("clue_")[-1].gsub("_", ",")
          
            # Get the answer:
            answer = Hpricot((clue/"div").first.attributes["onmouseover"])
            clue_params[:answer] = clean((answer/"em.correct_response").inner_html)
            q = Question.new(clue_params)
            q.save
          end
          g = Game.new(game_params)
          g.save
          puts "  done."
        rescue
          puts "  something went wrong fetching this game."
        end
      end
    end
  end
  
  task :metadata => :environment do
    (1..35).each do |season|
      season_page = doc("http://j-archive.com/showseason.php?season=#{season}")
      content = Hpricot((season_page/"#content").inner_html)
      puts "Fetching metadata for season #{season}."
      (content/"tr").each do |game_row|
        tr = Hpricot(game_row.inner_html)
        game_id = (tr/"a").first.attributes["href"].split("game_id=")[-1].to_i
        puts "  > #{game_id}"
        begin
          g = Game.find_by_game_id(game_id)
          metadata = clean((tr/"td.left_padded").first.inner_html.strip)
          g.metadata = metadata unless metadata.nil? or metadata.empty?
          g.save
        rescue
          puts "Couldn't set metadata for game #{game_id}."
        end
      end
    end
  end
end
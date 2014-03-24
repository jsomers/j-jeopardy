class NgramGenerator
  # TODO: remove stopwords?
  class << self
    def ngram_redis
      $ngram_redis
    end
    
    def ngram_sorted_set_key(year, n)
      [year, n].join(":")
    end
    
    TOTAL_KEY = "ngram:totals"
    NGRAM_ALL_YEARS_KEY = "ngram:all_years"
    
    def ngrams(text, n)
      return unless stripped_text = text.to_s.squish.gsub(/[^\w\s\-]/, '').to_s.downcase.presence
      
      n = Array.wrap(n)
      words = stripped_text.split_to_words
      
      n.inject({}) do |hsh, this_n|
        this_ngrams = (0..(words.size - this_n)).map{|i| words[i, this_n]}
        
        hsh[this_n] = this_ngrams
        hsh
      end
    end
    
    def season_from_year(year)
      year - 1984
    end
    
    def year_from_season(season)
      2014 - (30 - season)
    end
    
    def go!(season)
      (1..4).each do |n|
        generate_ngram_data(year_from_season(season), n)
      end
    end
    
    def generate_ngram_data(year, n, opts = {})
      n = Array.wrap(n)
      
      keys = n.map { |num| ngram_sorted_set_key(year, num) }
      keys.each do |k|
        ngram_redis.del(k)
        ngram_redis.zrem(TOTAL_KEY, k)
      end
      ngram_redis.zrem(NGRAM_ALL_YEARS_KEY, year)
      
      Question.find_each(:joins => "join games on questions.game_id = games.game_id",
                         :conditions => "games.season = #{season_from_year(year)}") do |question|
        next unless ngrams_hsh = ngrams([question.question, question.answer].join(' '), n).presence
        
        ngrams_hsh.each do |num, ngrams_ary|
          this_key = ngram_sorted_set_key(year, num)
          
          ngram_redis.zincrby(TOTAL_KEY, ngrams_ary.size, this_key)
          
          ngrams_ary.each do |val|
            ngram_redis.zincrby(this_key, 1, val.join(" "))
          end
        end
      end
      
      unless opts[:no_trim]
        # drop ngrams for n >= 3 where there's only 1 occurrence
        n.select { |i| i >= 3 }.each do |i|
          ngram_redis.zremrangebyscore(ngram_sorted_set_key(year, i), 0, 1)
        end
      end
      
      ngram_redis.zadd(NGRAM_ALL_YEARS_KEY, year, year)
    end
  end
end

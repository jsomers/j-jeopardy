class QuestionNgram
  MAX_NGRAM_SIZE = 3
  TOTAL_KEY = "ngram:totals"
  NGRAM_ALL_YEARS_KEY = "ngram:all_years"
  
  def self.redis
    $ngram_redis
  end
  
  def self.all_years
    redis.zrange(NGRAM_ALL_YEARS_KEY, 0, 100).map(&:to_i)
    # (1988..2013).to_a
  end
  
  def self.sorted_set_key(year, n)
    [year, n].join(":")
  end
  
  def self.pretty_ngram_summary(year, n, options = {})
    key = sorted_set_key(year, n)
    raw = redis.zrevrange(key, options[:offset] || 0, (options[:limit] || 10) - 1, :with_scores => true)
    
    raw.map { |ary| puts "#{ary[0]} => #{ary[1]}" }
    nil
  end
  
  ALLOWED_MATH_OPERATORS = ["+", "/", "(", ")"]
  
  def self.get_terms_from_query_string(qry)
    regex = %r{[^\w\s\-\&#{ALLOWED_MATH_OPERATORS.join('')}]}
    qry.split(",").map{|t| t.squish.gsub(regex, '')}.select(&:present?)
  end
  
  def self.from_redis(string)
    qry, smoothing = string.split("::")
    
    terms = get_terms_from_query_string(qry)
    smoothing = smoothing.to_i if smoothing.present?
    
    {:query => terms.join(", "), :smoothing => smoothing, :raw => qry}
  end
  
  def self.recommended_query_hsh
    from_redis(Article.redis.srandmember("recommended_searches") || "Jordan, Kobe, LeBron")
  end
  
  def self.ngram_query(terms, opts = {})
    smoothing = opts[:smoothing] || 1
    case_sensitive = false
    
    preprocess_method = case_sensitive ? :to_s : :downcase
    
    terms_hsh = terms.inject(ActiveSupport::OrderedHash.new) do |hsh, term|
      key = term.dup
      hsh[key] = inner_query(term.send(preprocess_method), smoothing)
      hsh
    end
    
    {:terms => terms_hsh, :years => all_years, :smoothing => smoothing}
  end
  
  def self.equation_query(equation, smoothing)
    individual_terms = equation.split(%r{[#{ALLOWED_MATH_OPERATORS.join('')}]}).map(&:squish).uniq.select(&:present?)
    raise 'equation is too big!' if individual_terms.size > 10
    
    data_hsh = individual_terms.inject({}) do |hsh, t|
      hsh[t] = inner_query(t, smoothing)
      hsh
    end
    
    years = all_years
    output = []
    
    years.size.times do |ix|
      e = equation.dup
      data_hsh.keys.each do |t|
        e.gsub!(/\b#{t}\b/, data_hsh[t][ix].to_s)
      end
      
      raw_value = eval(e)
      
      output << (raw_value.infinite? ? nil : raw_value)
    end
    
    return output
  end
  
  def self.inner_query(term, smoothing)
    return equation_query(term, smoothing) if term.is_equation?
    
    term.squish!
    n = term.split(" ").size
    
    years = all_years
    
    counts_hsh, totals_hsh = {}, {}
    
    redis.pipelined do
      years.each do |year|
        key = sorted_set_key(year, n)
        
        counts_hsh[year] = redis.zscore(key, term)
        totals_hsh[year] = redis.zscore(TOTAL_KEY, key)
      end
    end
    
    counts = counts_hsh.sort_by{|year, val| year}.map{|ary| ary[1].value.to_f}
    totals = totals_hsh.sort_by{|year, val| year}.map{|ary| ary[1].value.to_f}
    
    output = []
    number_of_years = years.size
    
    number_of_years.times do |ix|
      lower = [0, ix - smoothing].max
      upper = [number_of_years - 1, ix + smoothing].min
      output << counts[lower..upper].sum / totals[lower..upper].sum
    end
    
    output
  end
  
  def self.from_redis(string)
    qry, smoothing = string.split("::")
    
    terms = get_terms_from_query_string(qry)
    smoothing = smoothing.to_i if smoothing.present?
    
    {:query => terms.join(", "), :smoothing => smoothing, :raw => qry}
  end
  
  def self.recommended_query_hsh
    from_redis(Article.redis.srandmember("recommended_searches") || "Jordan, Pippen, Kobe, LeBron::1")
  end
  
  def self.full_text_search(terms, opts = {})
    terms = terms.map(&:split_into_equation_components).flatten.uniq.select(&:present?)
  
    limit = opts[:limit] || 3
    n = terms.size
  
    exact_qry_text = ""
  
    terms.each_with_index do |t, ix|
      exact_qry_text << "#{' OR' if ix > 0} question LIKE ?"
    end
  
    exact_conditions = [exact_qry_text] + terms.map { |t| "% #{t.downcase} %" }
  
    articles = Question.all(:conditions => exact_conditions, :limit => limit, :order => "rand()")
    articles
  end
end
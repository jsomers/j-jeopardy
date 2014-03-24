class String
  def split_to_words
    scan(/(?:\w|-)+/)
  end
  
  def is_equation?
    QuestionNgram::ALLOWED_MATH_OPERATORS.any? { |op| self.include?(op) }
  end

  def is_too_long_to_be_a_valid_query?
    if is_equation?
      squish.split_into_equation_components.any? { |str| str.split(" ").size > QuestionNgram::MAX_NGRAM_SIZE }
    else
      squish.split(" ").size > QuestionNgram::MAX_NGRAM_SIZE
    end
  end
  
  def split_into_equation_components
    split(%r{[#{QuestionNgram::ALLOWED_MATH_OPERATORS.join('')}]}).map(&:squish).uniq
  end
end

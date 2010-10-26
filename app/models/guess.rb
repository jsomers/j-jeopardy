class Guess < ActiveRecord::Base
  belongs_to :question
  belongs_to :player
  
  def correct?
    false if self.guess.strip.empty?
    answer = self.question.answer
    guess_words = self.guess.downcase.split(" ")
    t = true
    for word in guess_words
      if !answer.downcase.include? word.downcase
        t = false
      end
    end
    t
  end
end

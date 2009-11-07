class Category < ActiveRecord::Base
  has_many :questions
  
  def self.new_if_needed(name)
    c = Category.find_by_name(name)
    if c.nil?
      c = Category.new(:name => name)
      c.save
    end
    return c
  end
  
  def count_questions
    self.q_count = self.questions.length
    self.save
  end
end

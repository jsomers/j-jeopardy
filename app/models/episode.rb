class Episode < ActiveRecord::Base
  serialize :single_table
  serialize :double_table
  serialize :points
  
  has_and_belongs_to_many :players
  
  after_create :prepopulate
  
  def prepopulate
    points = [0, 0, 0]
    charts = [[], [], []]
    single_table = []
    for i in (1..6)
      a = []
      for j in (1..5)
        a << [2, 2, 2, 0, 0]
      end
      single_table << a
    end
    double_table = []
    for i in (1..6)
      a = []
      for j in (1..5)
        a << [2, 2, 2, 0, 0]
      end
      double_table << a
    end
    self.answered = 0
    self.single_table = single_table
    self.double_table = double_table
    self.points = points
    self.save
  end
end

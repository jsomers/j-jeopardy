class Episode < ActiveRecord::Base
  serialize :single_table
  serialize :double_table
  serialize :points
  serialize :charts
end

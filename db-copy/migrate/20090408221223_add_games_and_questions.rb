class AddGamesAndQuestions < ActiveRecord::Migration
  def self.up
    add_column('games', 'categories', :text)
  end

  def self.down
    remove_column('games', 'categories')
  end
end

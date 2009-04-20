class GameAndQuestionSchemas < ActiveRecord::Migration
  def self.up
    add_column('games', 'name', :text)
    add_column('games', 'season', :integer)
    
    add_column('questions', 'game_id', :integer)
    add_column('questions', 'question', :text)
    add_column('questions', 'answer', :text)
    add_column('questions', 'value', :text)
    add_column('questions', 'coord', :text)
  end

  def self.down
    remove_column('games', 'name')
    remove_column('games', 'season')

    remove_column('questions', 'game_id')
    remove_column('questions', 'question')
    remove_column('questions', 'answer')
    remove_column('questions', 'value')
    remove_column('questions', 'coord')
  end
end
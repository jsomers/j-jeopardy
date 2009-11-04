class AddGameId < ActiveRecord::Migration
  def self.up
    add_column('games', 'game_id', :integer)
    add_index('games', 'game_id', {:unique => true})
  end

  def self.down
    remove_index('games', 'game_id')
    remove_column('games', 'game_id')
  end
end

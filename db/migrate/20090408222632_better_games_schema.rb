class BetterGamesSchema < ActiveRecord::Migration
  def self.up
    remove_column('games', 'name')
    add_column('games', 'airdate', :text)
  end

  def self.down
    add_column('games', 'name', :text)
    remove_column('games', 'airdate')
  end
end

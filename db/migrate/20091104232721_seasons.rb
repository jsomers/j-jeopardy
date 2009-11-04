class Seasons < ActiveRecord::Migration
  def self.up
    add_column :seasons, :n_games, :integer
  end

  def self.down
    remove_column :seasons, :n_games
  end
end

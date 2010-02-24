class JoinEpsPlyrs < ActiveRecord::Migration
  def self.up
    create_table :episodes_players, :id => false do |t|
      t.integer :episode_id
      t.integer :player_id
    end
  end

  def self.down
    drop_table :episodes_players
  end
end

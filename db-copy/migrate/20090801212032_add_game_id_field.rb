class AddGameIdField < ActiveRecord::Migration
  def self.up
    add_column :episodes, :game_id, :integer
  end

  def self.down
    remove_column :episodes, :game_id
  end
end

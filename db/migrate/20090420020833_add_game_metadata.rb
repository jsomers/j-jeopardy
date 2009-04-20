class AddGameMetadata < ActiveRecord::Migration
  def self.up
    add_column('games', 'type', :text)
  end

  def self.down
    remove_column('games', 'type')
  end
end

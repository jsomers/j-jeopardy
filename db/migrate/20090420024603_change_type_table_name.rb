class ChangeTypeTableName < ActiveRecord::Migration
  def self.up
    remove_column('games', 'type')
    add_column('games', 'metadata', :text)
  end

  def self.down
    remove_column('games', 'metadata')
    add_column('games', 'type', :text)
  end
end

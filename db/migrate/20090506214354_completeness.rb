class Completeness < ActiveRecord::Migration
  def self.up
    add_column('completes', 'game_id', :integer)
    add_column('completes', 'complete', :boolean)
  end

  def self.down
    remove_column('completes', 'game_id')
    remove_column('completes', 'complete')
  end
end

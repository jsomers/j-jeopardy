class AttachGuesses < ActiveRecord::Migration
  def self.up
    add_column :guesses, :player_id, :integer
  end

  def self.down
    remove_column :guesses, :player_id
  end
end

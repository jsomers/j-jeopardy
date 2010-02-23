class GuessSource < ActiveRecord::Migration
  def self.up
    add_column :guesses, :source, :string, :default => "regular"
  end

  def self.down
    remove_column :guesses, :source
  end
end

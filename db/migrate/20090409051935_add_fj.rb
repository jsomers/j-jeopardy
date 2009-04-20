class AddFj < ActiveRecord::Migration
  def self.up
    add_column('questions', 'fj', :boolean, {:default => 0})
  end

  def self.down
    remove_column('questions', 'fj')
  end
end

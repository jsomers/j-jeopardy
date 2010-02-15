class Defaultqcount < ActiveRecord::Migration
  def self.up
    change_column :categories, :q_count, :integer, :default => 0
    change_column :games, :q_count, :integer, :default => 0
  end

  def self.down
    change_column :categories, :q_count, :integer, :default => nil
    change_column :games, :q_count, :integer, :default => nil
  end
end

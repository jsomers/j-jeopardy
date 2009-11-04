class FixQCount < ActiveRecord::Migration
  def self.up
    remove_column :questions, :count
    add_column :games, :q_count, :integer
  end

  def self.down
    add_column :questions, :count, :integer
    remove_column :games, :q_count
  end
end

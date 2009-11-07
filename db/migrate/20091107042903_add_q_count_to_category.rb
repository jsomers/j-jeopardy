class AddQCountToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :q_count, :integer
  end

  def self.down
    remove_column :categories, :q_count
  end
end

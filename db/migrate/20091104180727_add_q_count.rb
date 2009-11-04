class AddQCount < ActiveRecord::Migration
  def self.up
    add_column :questions, :count, :integer
  end

  def self.down
    remove_column :questions, :count
  end
end

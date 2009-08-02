class AddAnsweredCount < ActiveRecord::Migration
  def self.up
    remove_column :episodes, :finished
    add_column :episodes, :answered, :integer, :default => 0
  end

  def self.down
    add_column :episodes, :finished, :boolean
    remove_column :episodes, :answered
  end
end

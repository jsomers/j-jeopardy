class Addtemp < ActiveRecord::Migration
  def self.up
    add_column :players, :temp, :boolean, :default => 0
  end

  def self.down
    remove_column :players, :temp
  end
end

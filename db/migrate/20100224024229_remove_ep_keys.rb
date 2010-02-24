class RemoveEpKeys < ActiveRecord::Migration
  def self.up
    remove_column :episodes, :key
    remove_column :episodes, :charts
  end

  def self.down
    add_column :episodes, :key, :string
    add_column :episodes, :charts, :text
  end
end

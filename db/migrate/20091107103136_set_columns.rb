class SetColumns < ActiveRecord::Migration
  def self.up
    add_column :sets, :q_ids, :text
  end

  def self.down
    remove_column :sets, :q_ids
  end
end

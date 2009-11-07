class QuestionsetColumns < ActiveRecord::Migration
  def self.up
    add_column :questionsets, :q_ids, :text
  end

  def self.down
    remove_column :questionsets, :q_ids
  end
end

class AddCategories < ActiveRecord::Migration
  def self.up
    add_column('questions', 'category', :text)
  end

  def self.down
    remove_column('questions', 'category')
  end
end

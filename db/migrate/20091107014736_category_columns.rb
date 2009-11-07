class CategoryColumns < ActiveRecord::Migration
  def self.up
    add_column :categories, :name, :text
    remove_column :questions, :category
    add_column :questions, :category_id, :integer
  end

  def self.down
    remove_column :categories, :name
    add_column :questions, :category, :text
    remove_column :questions, :category_id
  end
end

class AddDisplayValues < ActiveRecord::Migration
  def self.up
    add_column :questions, :display_value, :string
  end

  def self.down
    remove_column :questions, :display_value
  end
end

class PlayerParams < ActiveRecord::Migration
  def self.up
    remove_column :players, :temp
    remove_column :players, :password
    remove_column :players, :salt
    remove_column :players, :handle
    add_column :players, :email, :string
  end

  def self.down
    add_column :players, :handle, :string
    add_column :players, :temp, :boolean, :default => false
    add_column :players, :password, :string
    add_column :players, :salt, :string
    remove_column :players, :email
  end
end

class HandlesAndPasswords < ActiveRecord::Migration
  def self.up
    add_column :players, :handle, :string
    add_column :players, :password, :string
    add_column :players, :salt, :string
  end

  def self.down
    remove_column :players, :handle
    remove_column :players, :password
    remove_column :players, :salt
  end
end

class RemoveAuthentication < ActiveRecord::Migration
  def self.up
    remove_column('players', 'password_hash')
    remove_column('players', 'password_salt')
    remove_column('players', 'email')
    remove_column('players', 'username')
  end

  def self.down
    add_column('players', 'password_hash', :string)
    add_column('players', 'password_salt', :string)
    add_column('players', 'email', :string)
    add_column('players', 'username', :string)
  end
end

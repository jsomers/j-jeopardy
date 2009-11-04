class DropUsers < ActiveRecord::Migration
  def self.up
    drop_table :users
  end

  def self.down
    create_table "users" do |t|
      t.string   "login",                     :limit => 40
      t.string   "name",                      :limit => 100, :default => ""
      t.string   "email",                     :limit => 100
      t.string   "crypted_password",          :limit => 40
      t.string   "salt",                      :limit => 40
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "remember_token",            :limit => 40
      t.datetime "remember_token_expires_at"
    end
  end
end

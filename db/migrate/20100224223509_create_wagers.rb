class CreateWagers < ActiveRecord::Migration
  def self.up
    create_table :wagers do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :wagers
  end
end

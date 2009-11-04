class CreatePlayers < ActiveRecord::Migration
  def self.up
    create_table :players do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :players
  end
end

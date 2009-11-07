class CreateSets < ActiveRecord::Migration
  def self.up
    create_table :sets do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :sets
  end
end

class AddCompleteness < ActiveRecord::Migration
  def self.up
    create_table :completeness do |t|
      t.integer :game_id
      t.boolean  :complete
    end
  end

  def self.down
    drop_table :completeness
  end
end

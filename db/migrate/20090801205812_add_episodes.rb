class AddEpisodes < ActiveRecord::Migration
  def self.up
    create_table :episodes do |t|
      t.string :key
      t.boolean :finished
      t.text :single_table
      t.text :double_table
      t.text :points
      t.text :charts
    end
  end

  def self.down
    drop_table :episodes
  end
end

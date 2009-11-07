class CreateQuestionsets < ActiveRecord::Migration
  def self.up
    create_table :questionsets do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :questionsets
  end
end

class CreateCompletes < ActiveRecord::Migration
  def self.up
    create_table :completes do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :completes
  end
end

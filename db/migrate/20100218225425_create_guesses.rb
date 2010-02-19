class CreateGuesses < ActiveRecord::Migration
  def self.up
    create_table :guesses do |t|
      t.integer :question_id
      t.string :guess
      t.timestamps
    end
  end

  def self.down
    drop_table :guesses
  end
end

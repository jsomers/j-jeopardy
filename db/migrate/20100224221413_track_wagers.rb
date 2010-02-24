class TrackWagers < ActiveRecord::Migration
  def self.up
    add_column :wagers, :my_score, :integer
    add_column :wagers, :their_scores, :text
    add_column :wagers, :question_id, :integer
    add_column :wagers, :player_id, :integer
  end

  def self.down
    remove_column :wagers, :my_score
    remove_column :wagers, :their_scores
    remove_column :wagers, :question_id
    remove_column :wagers, :player_id
  end
end

class WagerAmounts < ActiveRecord::Migration
  def self.up
    add_column :wagers, :amount, :integer
  end

  def self.down
    remove_column :wager, :amount
  end
end

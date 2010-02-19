class AddFirstLetterToPerson < ActiveRecord::Migration
  def self.up
    add_column :people,:first_letter,:string,:limit => 10
  end

  def self.down
    remove_column :people,:first_letter
  end
end

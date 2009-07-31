class AddFirstLetterToProject < ActiveRecord::Migration
  def self.up
    add_column :projects,:first_letter,:string,:limit => 1
  end

  def self.down
    remove_column :projects,:first_letter
  end
end

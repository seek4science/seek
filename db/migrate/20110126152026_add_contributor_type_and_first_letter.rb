class AddContributorTypeAndFirstLetter < ActiveRecord::Migration
  def self.up
    add_column :events, :contributor_type, :string
    add_column :events, :first_letter, :string, :limit => 1
  end

  def self.down
    remove_column :events, :contributor_type
    remove_column :events, :first_letter
  end
end

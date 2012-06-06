class AddContributorToStudy < ActiveRecord::Migration
  def self.up
    add_column :studies, :contributor_id, :integer
    add_column :studies, :contributor_type, :string
  end

  def self.down
    remove_column :studies, :contributor_type
    remove_column :studies, :contributor_id
  end
end

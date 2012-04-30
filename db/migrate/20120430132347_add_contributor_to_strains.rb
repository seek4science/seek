class AddContributorToStrains < ActiveRecord::Migration
  def self.up
    add_column :strains, :contributor_type, :string
    add_column :strains, :contributor_id, :integer

  end

  def self.down
    remove_column :strains, :contributor_type
    remove_column :strains, :contributor_id
  end
end

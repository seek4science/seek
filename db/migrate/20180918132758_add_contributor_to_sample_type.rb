class AddContributorToSampleType < ActiveRecord::Migration
  def change
    add_column :sample_types, :contributor_id, :integer
  end
end

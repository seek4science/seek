class AddContributorToAssayTypesAndTechnologyTypes < ActiveRecord::Migration
  def change
    add_column :assay_types, :contributor_id, :integer, :default=>nil
    add_column :technology_types, :contributor_id, :integer, :default=>nil
  end
end

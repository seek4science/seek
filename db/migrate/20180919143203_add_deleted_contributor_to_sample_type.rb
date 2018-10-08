class AddDeletedContributorToSampleType < ActiveRecord::Migration

  def change
    add_column :sample_types, :deleted_contributor, :string, default: nil
  end

end

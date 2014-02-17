class AddAssayTypeUriToAssay < ActiveRecord::Migration
  def change
    add_column :assays, :assay_type_uri, :string, :default=>nil
  end
end

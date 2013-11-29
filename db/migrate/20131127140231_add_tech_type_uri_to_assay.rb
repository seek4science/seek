class AddTechTypeUriToAssay < ActiveRecord::Migration
  def change
    add_column :assays, :technology_type_uri, :string, :default=>nil
  end
end

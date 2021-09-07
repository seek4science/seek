class AddAuthorFieldsToAssetsCreators < ActiveRecord::Migration[5.2]
  def change
    add_column :assets_creators, :pos, :integer, default: 0
    add_column :assets_creators, :family_name, :string
    add_column :assets_creators, :given_name, :string
    add_column :assets_creators, :orcid, :string
    add_column :assets_creators, :affiliation, :text
  end
end

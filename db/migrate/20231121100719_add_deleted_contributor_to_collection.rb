class AddDeletedContributorToCollection < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :deleted_contributor, :string
  end
end

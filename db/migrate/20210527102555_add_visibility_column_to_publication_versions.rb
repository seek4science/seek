class AddVisibilityColumnToPublicationVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :publication_versions, :visibility, :integer
  end
end

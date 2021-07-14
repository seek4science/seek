class ChangeColumnNamePublicationVersionsProjects < ActiveRecord::Migration[5.2]
  def change
    rename_column :projects_publication_versions, :publication_id, :version_id
  end
end

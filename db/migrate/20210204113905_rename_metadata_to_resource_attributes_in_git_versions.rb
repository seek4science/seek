class RenameMetadataToResourceAttributesInGitVersions < ActiveRecord::Migration[5.2]
  def change
    rename_column(:git_versions, :metadata, :resource_attributes)
  end
end

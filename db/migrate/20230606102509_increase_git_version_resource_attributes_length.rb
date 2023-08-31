class IncreaseGitVersionResourceAttributesLength < ActiveRecord::Migration[6.1]
  def change
    change_column :git_versions, :resource_attributes, :text, limit: 16.megabytes - 1
  end
end

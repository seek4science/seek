class RemoveLastUsedAt < ActiveRecord::Migration[6.1]
  def change
    remove_column :assets, :last_used_at, :datetime
    remove_column :collections, :last_used_at, :datetime
    remove_column :data_file_versions, :last_used_at, :datetime
    remove_column :data_files, :last_used_at, :datetime
    remove_column :document_versions, :last_used_at, :datetime
    remove_column :documents, :last_used_at, :datetime
    remove_column :file_template_versions, :last_used_at, :datetime
    remove_column :file_templates, :last_used_at, :datetime
    remove_column :model_versions, :last_used_at, :datetime
    remove_column :models, :last_used_at, :datetime
    remove_column :placeholders, :last_used_at, :datetime
    remove_column :presentation_versions, :last_used_at, :datetime
    remove_column :presentations, :last_used_at, :datetime
    remove_column :publication_versions, :last_used_at, :datetime
    remove_column :publications, :last_used_at, :datetime
    remove_column :sop_versions, :last_used_at, :datetime
    remove_column :sops, :last_used_at, :datetime
    remove_column :workflow_versions, :last_used_at, :datetime
    remove_column :workflows, :last_used_at, :datetime
  end
end

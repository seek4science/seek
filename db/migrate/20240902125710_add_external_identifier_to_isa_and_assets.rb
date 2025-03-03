class AddExternalIdentifierToISAAndAssets < ActiveRecord::Migration[6.1]
  def change
    add_column :investigations, :external_identifier, :string, limit: 2048
    add_column :studies, :external_identifier, :string, limit: 2048
    add_column :assays, :external_identifier, :string, limit: 2048
    add_column :observation_units, :external_identifier, :string, limit: 2048
    add_column :data_files, :external_identifier, :string, limit: 2048
    add_column :models, :external_identifier, :string, limit: 2048
    add_column :sops, :external_identifier, :string, limit: 2048
    add_column :presentations, :external_identifier, :string, limit: 2048
    add_column :workflows, :external_identifier, :string, limit: 2048
    add_column :documents, :external_identifier, :string, limit: 2048
    add_column :samples, :external_identifier, :string, limit: 2048
    add_column :strains, :external_identifier, :string, limit: 2048
    add_column :publications, :external_identifier, :string, limit: 2048
    add_column :collections, :external_identifier, :string, limit: 2048
    add_column :placeholders, :external_identifier, :string, limit: 2048
    add_column :file_templates, :external_identifier, :string, limit: 2048
    add_column :templates, :external_identifier, :string, limit: 2048
    add_column :sample_types, :external_identifier, :string, limit: 2048
  end
end

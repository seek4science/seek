class AddPolicyIdIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :assays, :policy_id
    add_index :assets, :policy_id
    add_index :data_file_versions, :policy_id
    add_index :data_files, :policy_id
    add_index :document_versions, :policy_id
    add_index :documents, :policy_id
    add_index :events, :policy_id
    add_index :fair_data_station_uploads, :policy_id
    add_index :investigations, :policy_id
    add_index :model_versions, :policy_id
    add_index :models, :policy_id
    add_index :observation_units, :policy_id
    add_index :openbis_endpoints, :policy_id
    add_index :presentation_versions, :policy_id
    add_index :presentations, :policy_id
    add_index :publication_versions, :policy_id
    add_index :publications, :policy_id
    add_index :sample_types, :policy_id
    add_index :samples, :policy_id
    add_index :sop_versions, :policy_id
    add_index :sops, :policy_id
    add_index :strains, :policy_id
    add_index :studies, :policy_id
    add_index :templates, :policy_id
    add_index :workflow_versions, :policy_id
    add_index :workflows, :policy_id
  end
end

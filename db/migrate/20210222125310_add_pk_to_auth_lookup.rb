class AddPkToAuthLookup < ActiveRecord::Migration[5.2]
  def change
    add_column :assay_auth_lookup, :id, :primary_key          
    add_column :data_file_auth_lookup, :id, :primary_key
    add_column :document_auth_lookup, :id, :primary_key
    add_column :event_auth_lookup, :id, :primary_key
    add_column :investigation_auth_lookup, :id, :primary_key
    add_column :model_auth_lookup, :id, :primary_key
    add_column :node_auth_lookup, :id, :primary_key
    add_column :presentation_auth_lookup, :id, :primary_key
    add_column :publication_auth_lookup, :id, :primary_key
    add_column :sample_auth_lookup, :id, :primary_key
    add_column :sop_auth_lookup, :id, :primary_key
    add_column :strain_auth_lookup, :id, :primary_key
    add_column :study_auth_lookup, :id, :primary_key
    add_column :workflow_auth_lookup, :id, :primary_key
  end
end

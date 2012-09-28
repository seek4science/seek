class UpdatedAuthLookupTablesToUseUserId < ActiveRecord::Migration

  def self.up
    rename_column :assay_auth_lookup,:person_id, :user_id
    rename_column :data_file_auth_lookup,:person_id, :user_id
    rename_column :event_auth_lookup,:person_id, :user_id
    rename_column :investigation_auth_lookup,:person_id, :user_id
    rename_column :model_auth_lookup,:person_id, :user_id
    rename_column :presentation_auth_lookup,:person_id, :user_id
    rename_column :publication_auth_lookup,:person_id, :user_id
    rename_column :sample_auth_lookup,:person_id, :user_id
    rename_column :sop_auth_lookup,:person_id, :user_id
    rename_column :specimen_auth_lookup,:person_id, :user_id
    rename_column :study_auth_lookup,:person_id, :user_id

    #probbaly not necessary on mysql, but may be on sqlite and cleans up the index name
    remove_index :assay_auth_lookup, [:person_id,:can_view]
    add_index :assay_auth_lookup, [:user_id, :can_view]

    remove_index :data_file_auth_lookup, [:person_id,:can_view]
    add_index :data_file_auth_lookup, [:user_id, :can_view]

    remove_index :event_auth_lookup, [:person_id,:can_view]
    add_index :event_auth_lookup, [:user_id, :can_view]

    remove_index :investigation_auth_lookup, [:person_id,:can_view]
    add_index :investigation_auth_lookup, [:user_id, :can_view]

    remove_index :model_auth_lookup, [:person_id,:can_view]
    add_index :model_auth_lookup, [:user_id, :can_view]

    remove_index :presentation_auth_lookup, [:person_id,:can_view]
    add_index :presentation_auth_lookup, [:user_id, :can_view]

    remove_index :publication_auth_lookup, [:person_id,:can_view]
    add_index :publication_auth_lookup, [:user_id, :can_view]

    remove_index :sample_auth_lookup, [:person_id,:can_view]
    add_index :sample_auth_lookup, [:user_id, :can_view]

    remove_index :sop_auth_lookup, [:person_id,:can_view]
    add_index :sop_auth_lookup, [:user_id, :can_view]

    remove_index :specimen_auth_lookup, [:person_id,:can_view]
    add_index :specimen_auth_lookup, [:user_id, :can_view]

    remove_index :study_auth_lookup, [:person_id,:can_view]
    add_index :study_auth_lookup, [:user_id, :can_view]
  end

  def self.down
    rename_column :assay_auth_lookup,:user_id,:person_id
    rename_column :data_file_auth_lookup,:user_id,:person_id
    rename_column :event_auth_lookup,:user_id,:person_id
    rename_column :investigation_auth_lookup,:user_id,:person_id
    rename_column :model_auth_lookup,:user_id,:person_id
    rename_column :presentation_auth_lookup,:user_id,:person_id
    rename_column :publication_auth_lookup,:user_id,:person_id
    rename_column :sample_auth_lookup,:user_id,:person_id
    rename_column :sop_auth_lookup,:user_id,:person_id
    rename_column :specimen_auth_lookup,:user_id,:person_id
    rename_column :study_auth_lookup,:user_id,:person_id

    remove_index :assay_auth_lookup, [:user_id,:can_view]
    add_index :assay_auth_lookup, [:person_id, :can_view]

    remove_index :data_file_auth_lookup, [:user_id,:can_view]
    add_index :data_file_auth_lookup, [:person_id, :can_view]

    remove_index :event_auth_lookup, [:user_id,:can_view]
    add_index :event_auth_lookup, [:person_id, :can_view]

    remove_index :investigation_auth_lookup, [:user_id,:can_view]
    add_index :investigation_auth_lookup, [:person_id, :can_view]

    remove_index :model_auth_lookup, [:user_id,:can_view]
    add_index :model_auth_lookup, [:person_id, :can_view]

    remove_index :presentation_auth_lookup, [:user_id,:can_view]
    add_index :presentation_auth_lookup, [:person_id, :can_view]

    remove_index :publication_auth_lookup, [:user_id,:can_view]
    add_index :publication_auth_lookup, [:person_id, :can_view]

    remove_index :sample_auth_lookup, [:user_id,:can_view]
    add_index :sample_auth_lookup, [:person_id, :can_view]

    remove_index :sop_auth_lookup, [:user_id,:can_view]
    add_index :sop_auth_lookup, [:person_id, :can_view]

    remove_index :specimen_auth_lookup, [:user_id,:can_view]
    add_index :specimen_auth_lookup, [:person_id, :can_view]

    remove_index :study_auth_lookup, [:user_id,:can_view]
    add_index :study_auth_lookup, [:person_id, :can_view]
  end
end

class RenameIndexOnExtendedMetadataAttributes < ActiveRecord::Migration[6.1]
  def change
    rename_index :extended_metadata_attributes, 'index_extended_metadata_attributes_on_sample_controlled_vocab_id', 'index_extended_metadata_attributes_on_sample_cv_id'
  end
end

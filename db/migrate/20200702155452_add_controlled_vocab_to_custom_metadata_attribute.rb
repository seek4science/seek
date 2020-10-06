class AddControlledVocabToCustomMetadataAttribute < ActiveRecord::Migration[5.2]
  def change
    add_reference :custom_metadata_attributes, :sample_controlled_vocab
  end
end

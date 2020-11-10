class DeleteOntologyFieldsToSampleControlledVocabTerm < ActiveRecord::Migration[5.2]
  def change
    remove_column :sample_controlled_vocab_terms, :source_ontology,  :string
    remove_column :sample_controlled_vocab_terms, :parent_class, :string
    remove_column :sample_controlled_vocab_terms, :short_name, :string
    remove_column :sample_controlled_vocab_terms, :description, :text
    remove_column :sample_controlled_vocab_terms, :required , :boolean
  end
end

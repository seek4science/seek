class AddOntologyFieldsToSampleControlledVocabTerm < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_controlled_vocab_terms, :source_ontology,  :string
    add_column :sample_controlled_vocab_terms, :parent_class, :string
    add_column :sample_controlled_vocab_terms, :short_name, :string
    add_column :sample_controlled_vocab_terms, :description, :text
    add_column :sample_controlled_vocab_terms, :required , :boolean
  end
end

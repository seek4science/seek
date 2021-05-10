class AddIriAndParentIriToSampleControlledVocabTerm < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_controlled_vocab_terms, :iri,  :string
    add_column :sample_controlled_vocab_terms, :parent_iri, :string
  end
end

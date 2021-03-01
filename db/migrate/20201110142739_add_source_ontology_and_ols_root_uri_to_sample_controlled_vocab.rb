class AddSourceOntologyAndOlsRootUriToSampleControlledVocab < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_controlled_vocabs, :source_ontology, :string
    add_column :sample_controlled_vocabs, :ols_root_term_uri, :string
    add_column :sample_controlled_vocabs, :required, :boolean
    add_column :sample_controlled_vocabs, :short_name, :string
  end
end

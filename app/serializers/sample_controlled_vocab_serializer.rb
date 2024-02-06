class SampleControlledVocabSerializer < BaseSerializer
  attributes :title, :description, :source_ontology, :ols_root_term_uris, :short_name
  attributes :sample_controlled_vocab_terms_attributes
  
  has_many :sample_controlled_vocab_terms

  def sample_controlled_vocab_terms_attributes
    object.sample_controlled_vocab_terms.collect do |term|
     { 
       id: term.id.to_s,
       label: term.label,
       iri: term.iri,
       parent_iri: term.parent_iri,
     }
    end
  end
end

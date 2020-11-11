class SampleControlledVocabSerializer < BaseSerializer
  attributes :title, :description, :source_ontology, :ols_root_term_uri, :required, :short_name
  attributes :sample_controlled_vocab_terms_attributes
  attributes :repository_standard_attributes
  
  has_many :sample_controlled_vocab_terms

  def repository_standard_attributes
    repo = object.repository_standard
     if repo
      {
        id: repo.id,
        title: repo.title,
        url: repo.url,
        group_tag: repo.group_tag,
        repo_type: repo.repo_type,
        description: repo.description
      }
    end
  end

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

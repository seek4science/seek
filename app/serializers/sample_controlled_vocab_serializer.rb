class SampleControlledVocabSerializer < BaseSerializer
  attributes :title, :description, :group, :item_type
  attributes :sample_controlled_vocab_terms_attributes

  has_many :sample_controlled_vocab_terms

  def sample_controlled_vocab_terms_attributes
    object.sample_controlled_vocab_terms.collect do |term|
     { 
       id: term.id.to_s,
       label: term.label,
       source_ontology: term.source_ontology,
       parent_class: term.parent_class,
       short_name: term.short_name,
       description: term.description,
       required: term.required.to_s,
       ontology_labels_attributes: term.ontology_labels.collect # The labels and IRIs
     }
    end
  end
end

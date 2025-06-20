DISCIPLINES = %(
Chemistry
Computer Science
Earth Science
Health Science
Life Science
Space Science
Social Science
Astronomy
Physics
Climate Science
Humanities
Library Science
Cross-cutting
Environmental Science
Engineering
Mathematics
Neuroscience
).split('\n').map(&:strip).compact_blank.freeze

data = {
  title: 'Scientific disciplines',
  description: 'A list of scientific disciplines.',
  ols_root_term_uris: '',
  source_ontology: '',
  sample_controlled_vocab_terms_attributes: DISCIPLINES.map do |d|
    {
      label: d,
      iri: '',
      parent_iri: ''
    }
  end
}.with_indifferent_access

Seek::Data::SeedControlledVocab.seed(data, :disciplines)

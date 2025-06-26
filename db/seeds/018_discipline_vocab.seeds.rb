# Made up from a subset of EDAM Topics, plus some others
DISCIPLINES = [
  { label: 'Astronomy', iri: '' },
  { label: 'Chemistry', iri: 'http://edamontology.org/topic_3314' },
  { label: 'Climate Science', iri: '' },
  { label: 'Computer Science', iri: 'http://edamontology.org/topic_3316' },
  { label: 'Cross-discipline', iri: '' },
  { label: 'Earth Science', iri: '' },
  { label: 'Engineering', iri: '' },
  { label: 'Environmental Science', iri: 'http://edamontology.org/topic_3855' },
  { label: 'Humanities', iri: '' },
  { label: 'Library Science', iri: '' },
  { label: 'Life Science', iri: 'http://edamontology.org/topic_4019' },
  { label: 'Machine Learning', iri: 'http://edamontology.org/topic_3474' },
  { label: 'Mathematics', iri: 'http://edamontology.org/topic_3315' },
  { label: 'Medicine', iri: 'http://edamontology.org/topic_3303' },
  { label: 'Physics', iri: 'http://edamontology.org/topic_3318' },
  { label: 'Social Science', iri: '' }
].freeze

data = {
  title: 'Scientific disciplines',
  description: 'A list of scientific disciplines.',
  ols_root_term_uris: 'http://edamontology.org/topic_0003',
  source_ontology: 'edam',
  sample_controlled_vocab_terms_attributes: DISCIPLINES.map do |d|
    d[:parent_iri] = 'http://edamontology.org/topic_0003' if d[:iri].present?
    d
  end
}

Seek::Data::SeedControlledVocab.seed(data.with_indifferent_access, :disciplines)

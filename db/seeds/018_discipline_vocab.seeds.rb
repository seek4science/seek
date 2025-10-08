FIELDS = JSON.parse(File.read(Rails.root.join('config', 'default_data', 'controlled-vocabs', 'openalex_fields.json')))

data = {
  title: 'Scientific disciplines',
  description: 'A list of scientific disciplines, from https://openalex.org/',
  ols_root_term_uris: '',
  source_ontology: '',
  sample_controlled_vocab_terms_attributes: FIELDS.flat_map do |domain|
    domain['fields'].map do |field|
      {
        label: field['display_name'],
        iri: field['id'],
        parent_iri: domain['id']
      }
    end
  end
}

Seek::Data::SeedControlledVocab.seed(data.with_indifferent_access, :disciplines)

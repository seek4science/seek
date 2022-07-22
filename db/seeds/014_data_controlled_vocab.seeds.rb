json = File.read(File.join(Rails.root, "config/default_data", "data-annotations-controlled-vocab.json"))
data = JSON.parse(json).with_indifferent_access

unless vocab = SampleControlledVocab::SystemVocabs.vocab_for_property(:data_types)
  puts "Seeding Data controlled vocabulary ..."
  vocab = SampleControlledVocab.new(title: data[:title],
                                    key: SampleControlledVocab::SystemVocabs.database_key_for_property(:data_types),
                                    description: data[:description],
                                    source_ontology: data[:source_ontology],
                                    ols_root_term_uri: data[:ols_root_term_uri])
  data[:terms].each do |term|
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: term[:label], iri: term[:iri], parent_iri: term[:parent_iri])
  end

  disable_authorization_checks do
    vocab.save!
  end

  puts "... Done"
else
  puts "Data type controlled vocabulary already exists, updating its metadata"
  disable_authorization_checks do
    vocab.update(data.except(:terms))
  end
end

unless SampleControlledVocab.find_by_key(SampleControlledVocab::SystemVocabs::KEYS[:edam_data])
  puts "Seeding EDAM Data ontology ..."
  json = File.read(File.join(Rails.root, "config/default_data", "edam-data-controlled-vocab.json"))
  data = JSON.parse(json).with_indifferent_access
  vocab = SampleControlledVocab.new(title: data[:title],
                                    key: SampleControlledVocab::SystemVocabs::KEYS[:edam_data],
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
  puts "EDAM Data already exists"
end

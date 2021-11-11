unless SampleControlledVocab.find_by_key(SampleControlledVocab::EDAM_TOPICS_KEY)
  puts "Seeding EDAM Topics ontology ..."
  json = File.read(File.join(Rails.root, "config/default_data", "edam-topics-controlled-vocab.json"))
  data = JSON.parse(json).with_indifferent_access
  vocab = SampleControlledVocab.new(title: data[:title],
                                    key: SampleControlledVocab::EDAM_TOPICS_KEY,
                                    description: data[:description],
                                    source_ontology: data[:source_ontology],
                                    ols_root_term_uri: data[:ols_root_term_uri],
                                    short_name: data[:short_name])
  data[:terms].each do |term|
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: term[:label], iri: term[:iri], parent_iri: term[:parent_iri])
  end

  disable_authorization_checks do
    vocab.save!
  end

else
  puts "EDAM Topics already exists"
end

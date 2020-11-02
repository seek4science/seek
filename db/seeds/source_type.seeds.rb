
sources = YAML.load_file(File.join(Rails.root, 'config/default_data/source_types.yml')).values
disable_authorization_checks do
    sources.each do |source|
        source_type = source['source_type'] == 'study' ? 0 : 1
        s = SampleControlledVocab.find_or_create_by(title: source['name'], group:source['group'] , item_type: source_type)
        attributes = source['attributes']
        attributes.each do |attribute|
            attribute.each do |property|
                required = property[1]['title'].include? "*"
                name = property[1]['title'].sub '*', ''
                parent_class = property[1]['IRI']
                short_name = property[1]['short_name']
                description = property[1]['description'] 
                s.sample_controlled_vocab_terms.find_or_create_by(
                    label: name,
                    source_ontology: "",
                    parent_class: parent_class,
                    required: required,
                    short_name: short_name,
                    description: description
                )
            end
        end
    end
end

puts "Seeded default sample controlled vocabs"
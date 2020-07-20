
sources = YAML.load_file(File.join(Rails.root, 'config/default_data/source_types.yml')).values
sources.each do |source|
    source_type = source['source_type'] == 'study' ? 0 : 1
    s = SourceType.find_or_create_by(name: source['name'], group:source['group'] ,source_type: source_type)
    attributes = source['attributes']
    attributes.each do |attribute|
        attribute.each do |property|
            required = property[1]['title'].include? "*"
            name = property[1]['title'].sub '*', ''
            link = property[1]['IRI']
            short_name = property[1]['short_name']
            description = property[1]['description'] 
            s.source_attributes.find_or_create_by(name: name, required: required, IRI: link, 
                short_name: short_name, description: description)
        end
      
    end
end

puts "Seeded default source types"




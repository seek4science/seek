# Sample attribute types
count = SampleAttributeType.count
SampleAttributeType.find_or_initialize_by_title('Date time').update_attributes(base_type: Seek::Samples::BaseType::DATE_TIME, placeholder: 'January 1, 2015 11:30 AM')
SampleAttributeType.find_or_initialize_by_title('Date').update_attributes(base_type: Seek::Samples::BaseType::DATE, placeholder: 'January 1, 2015')
SampleAttributeType.find_or_initialize_by_title('Float').update_attributes(title: 'Real number') unless SampleAttributeType.where(title: 'Real number').first
SampleAttributeType.find_or_initialize_by_title('Real number').update_attributes(base_type: Seek::Samples::BaseType::FLOAT, placeholder: '3.6')
SampleAttributeType.find_or_initialize_by_title('Integer').update_attributes(base_type: Seek::Samples::BaseType::INTEGER, placeholder: '1')
SampleAttributeType.find_or_initialize_by_title('Web link').update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp(%w(http https)).to_s, placeholder: 'http://www.example.com')
SampleAttributeType.find_or_initialize_by_title('Email address').update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: RFC822::EMAIL.to_s, placeholder: 'someone@example.com')
SampleAttributeType.find_or_initialize_by_title('Text').update_attributes(base_type: Seek::Samples::BaseType::TEXT)
SampleAttributeType.find_or_initialize_by_title('String').update_attributes(base_type: Seek::Samples::BaseType::STRING)
SampleAttributeType.find_or_initialize_by_title('CHEBI ID').update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: 'CHEBI:[0-9]+', placeholder: 'CHEBI:1234')
SampleAttributeType.find_or_initialize_by_title('Boolean').update_attributes(base_type: Seek::Samples::BaseType::BOOLEAN)
SampleAttributeType.find_or_initialize_by_title('SEEK Strain').update_attributes(base_type: Seek::Samples::BaseType::SEEK_STRAIN)
SampleAttributeType.find_or_initialize_by_title('SEEK Sample').update_attributes(base_type: Seek::Samples::BaseType::SEEK_SAMPLE)
SampleAttributeType.find_or_initialize_by_title('Controlled Vocabulary').update_attributes(base_type: Seek::Samples::BaseType::CV)
SampleAttributeType.find_or_initialize_by_title('URI').update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp.to_s, placeholder: 'http://www.example.com/123')

puts "Seeded #{SampleAttributeType.count - count} sample attribute types."

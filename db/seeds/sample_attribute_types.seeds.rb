# Sample attribute types
count = SampleAttributeType.count
SampleAttributeType.find_or_create_by_title('Date time', base_type:Seek::Samples::BaseType::DATE_TIME)
SampleAttributeType.find_or_create_by_title('Date',base_type:Seek::Samples::BaseType::DATE)
SampleAttributeType.find_or_create_by_title("Integer", base_type:Seek::Samples::BaseType::INTEGER)
SampleAttributeType.find_or_create_by_title("Float", base_type:Seek::Samples::BaseType::FLOAT)
SampleAttributeType.find_or_create_by_title("Web link",base_type:Seek::Samples::BaseType::STRING,regexp:URI.regexp(%w(http https)).to_s)
SampleAttributeType.find_or_create_by_title("Email address",base_type:Seek::Samples::BaseType::STRING,regexp:RFC822::EMAIL.to_s)
SampleAttributeType.find_or_create_by_title("Text",base_type:Seek::Samples::BaseType::TEXT)
SampleAttributeType.find_or_create_by_title("String", base_type: Seek::Samples::BaseType::STRING)
SampleAttributeType.find_or_create_by_title("CHEBI ID",regexp:'CHEBI:[0-9]+', base_type:Seek::Samples::BaseType::STRING)
SampleAttributeType.find_or_create_by_title("Boolean",base_type:Seek::Samples::BaseType::BOOLEAN)
SampleAttributeType.find_or_create_by_title("SEEK Strain",base_type:Seek::Samples::BaseType::SEEK_STRAIN)
SampleAttributeType.find_or_create_by_title("SEEK Sample",base_type:Seek::Samples::BaseType::SEEK_SAMPLE)
SampleAttributeType.find_or_create_by_title("Controlled Vocabulary",base_type:Seek::Samples::BaseType::CV)

puts "Seeded #{SampleAttributeType.count - count} sample attribute types."

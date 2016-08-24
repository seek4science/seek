# Sample attribute types
count = SampleAttributeType.count
SampleAttributeType.find_or_create_by_title('Date time', base_type:'DateTime')
SampleAttributeType.find_or_create_by_title('Date',base_type:'Date')
SampleAttributeType.find_or_create_by_title("Integer", base_type:'Integer')
SampleAttributeType.find_or_create_by_title("Float", base_type:'Float')
SampleAttributeType.find_or_create_by_title("Web link",base_type:'String',regexp:URI.regexp(%w(http https)).to_s)
SampleAttributeType.find_or_create_by_title("Email address",base_type:'String',regexp:RFC822::EMAIL.to_s)
SampleAttributeType.find_or_create_by_title("Text",base_type:'Text')
SampleAttributeType.find_or_create_by_title("String", base_type: 'String')
SampleAttributeType.find_or_create_by_title("CHEBI ID",regexp:'CHEBI:[0-9]+', base_type:'String')
SampleAttributeType.find_or_create_by_title("Boolean",base_type:'Boolean')
SampleAttributeType.find_or_create_by_title("SEEK Strain",base_type:'SeekStrain')
SampleAttributeType.find_or_create_by_title("SEEK Sample",base_type:'SeekSample')
SampleAttributeType.find_or_create_by_title("Controlled Vocabulary",base_type:'CV')

puts "Seeded #{SampleAttributeType.count - count} sample attribute types."

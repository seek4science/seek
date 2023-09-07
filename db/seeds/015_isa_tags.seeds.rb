# ISA tags
source = IsaTag.find_or_initialize_by(title: 'source')
source.save
source_characteristic = IsaTag.find_or_initialize_by(title: 'source_characteristic')
source_characteristic.save
sample = IsaTag.find_or_initialize_by(title: 'sample')
sample.save
sample_characteristic = IsaTag.find_or_initialize_by(title: 'sample_characteristic')
sample_characteristic.save
protocol = IsaTag.find_or_initialize_by(title: 'protocol')
protocol.save
other_material = IsaTag.find_or_initialize_by(title: 'other_material')
other_material.save
other_material_characteristic = IsaTag.find_or_initialize_by(title: 'other_material_characteristic')
other_material_characteristic.save
data_file = IsaTag.find_or_initialize_by(title: 'data_file')
data_file.save
data_file_comment = IsaTag.find_or_initialize_by(title: 'data_file_comment')
data_file_comment.save
parameter_value = IsaTag.find_or_initialize_by(title: 'parameter_value')
parameter_value.save

puts 'Seeded isa tags'

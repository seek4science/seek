# ISA tags
source = ISATag.find_or_initialize_by(title: 'source')
source.save
source_characteristic = ISATag.find_or_initialize_by(title: 'source_characteristic')
source_characteristic.save
sample = ISATag.find_or_initialize_by(title: 'sample')
sample.save
sample_characteristic = ISATag.find_or_initialize_by(title: 'sample_characteristic')
sample_characteristic.save
protocol = ISATag.find_or_initialize_by(title: 'protocol')
protocol.save
other_material = ISATag.find_or_initialize_by(title: 'other_material')
other_material.save
other_material_characteristic = ISATag.find_or_initialize_by(title: 'other_material_characteristic')
other_material_characteristic.save
data_file = ISATag.find_or_initialize_by(title: 'data_file')
data_file.save
data_file_comment = ISATag.find_or_initialize_by(title: 'data_file_comment')
data_file_comment.save
parameter_value = ISATag.find_or_initialize_by(title: 'parameter_value')
parameter_value.save
input = ISATag.find_or_initialize_by(title: 'input')
input.save

puts 'Seeded isa tags'

# Sample Types and Samples

# First, we need to create sample attribute types
string_attr_type = SampleAttributeType.where(title: 'String').first_or_create(base_type: 'String')
float_attr_type = SampleAttributeType.where(title: 'Real number').first_or_create(base_type: 'Float')
integer_attr_type = SampleAttributeType.where(title: 'Integer').first_or_create(base_type: 'Integer')
boolean_attr_type = SampleAttributeType.where(title: 'Boolean').first_or_create(base_type: 'Boolean')

# Create a sample type for bacterial culture samples
culture_sample_type = SampleType.new(
  title: 'Bacterial Culture',
  description: 'Sample type for bacterial culture experiments related to thermophile studies'
)
culture_sample_type.projects = [$project]
culture_sample_type.contributor = $guest_person
culture_sample_type.policy = Policy.create(name: 'default policy', access_type: 1)

# Add attributes to the sample type
culture_sample_type.sample_attributes.build(
  title: 'Culture Name',
  sample_attribute_type: string_attr_type,
  required: true,
  is_title: true
)

culture_sample_type.sample_attributes.build(
  title: 'Strain Used',
  sample_attribute_type: string_attr_type,
  required: true,
  description: 'The bacterial strain used for this culture'
)

culture_sample_type.sample_attributes.build(
  title: 'Growth Temperature (°C)',
  sample_attribute_type: float_attr_type,
  required: true,
  description: 'Temperature at which the culture was grown'
)

culture_sample_type.sample_attributes.build(
  title: 'Culture Volume (mL)',
  sample_attribute_type: float_attr_type,
  required: false,
  description: 'Volume of the bacterial culture'
)

culture_sample_type.sample_attributes.build(
  title: 'pH',
  sample_attribute_type: float_attr_type,
  required: false,
  description: 'pH of the culture medium'
)

culture_sample_type.sample_attributes.build(
  title: 'Growth Phase Complete',
  sample_attribute_type: boolean_attr_type,
  required: false,
  description: 'Whether the culture has reached stationary phase'
)

disable_authorization_checks { culture_sample_type.save! }
culture_sample_type.annotate_with(['bacterial culture', 'thermophile', 'microbiology'], 'tag', $guest_person)
puts 'Seeded bacterial culture sample type.'

# Create a sample type for enzyme preparations
enzyme_sample_type = SampleType.new(
  title: 'Enzyme Preparation',
  description: 'Sample type for purified enzyme preparations used in reconstituted systems'
)
enzyme_sample_type.projects = [$project]
enzyme_sample_type.contributor = $guest_person
enzyme_sample_type.policy = Policy.create(name: 'default policy', access_type: 1)

enzyme_sample_type.sample_attributes.build(
  title: 'Enzyme Name',
  sample_attribute_type: string_attr_type,
  required: true,
  is_title: true
)

enzyme_sample_type.sample_attributes.build(
  title: 'EC Number',
  sample_attribute_type: string_attr_type,
  required: false,
  description: 'Enzyme Commission number'
)

enzyme_sample_type.sample_attributes.build(
  title: 'Concentration (mg/mL)',
  sample_attribute_type: float_attr_type,
  required: true,
  description: 'Protein concentration of the enzyme preparation'
)

enzyme_sample_type.sample_attributes.build(
  title: 'Specific Activity (U/mg)',
  sample_attribute_type: float_attr_type,
  required: false,
  description: 'Specific enzymatic activity'
)

enzyme_sample_type.sample_attributes.build(
  title: 'Storage Temperature (°C)',
  sample_attribute_type: integer_attr_type,
  required: false,
  description: 'Temperature for enzyme storage'
)

enzyme_sample_type.sample_attributes.build(
  title: 'Purification Steps',
  sample_attribute_type: integer_attr_type,
  required: false,
  description: 'Number of purification steps performed'
)

disable_authorization_checks { enzyme_sample_type.save! }
enzyme_sample_type.annotate_with(['enzyme', 'protein', 'purification'], 'tag', $guest_person)
puts 'Seeded enzyme preparation sample type.'

# Now create actual samples

# Bacterial culture samples
culture1 = Sample.new(title: 'S. solfataricus Culture #1')
culture1.sample_type = culture_sample_type
culture1.projects = [$project]
culture1.contributor = $guest_person
culture1.policy = Policy.create(name: 'default policy', access_type: 1)
culture1.set_attribute_value('Culture Name', 'S. solfataricus Culture #1')
culture1.set_attribute_value('Strain Used', 'Sulfolobus solfataricus strain 98/2')
culture1.set_attribute_value('Growth Temperature (°C)', 80.0)
culture1.set_attribute_value('Culture Volume (mL)', 500.0)
culture1.set_attribute_value('pH', 2.5)
culture1.set_attribute_value('Growth Phase Complete', true)
disable_authorization_checks { culture1.save! }
puts 'Seeded bacterial culture sample 1.'

culture2 = Sample.new(title: 'S. solfataricus Culture #2')
culture2.sample_type = culture_sample_type
culture2.projects = [$project]
culture2.contributor = $guest_person
culture2.policy = Policy.create(name: 'default policy', access_type: 1)
culture2.set_attribute_value('Culture Name', 'S. solfataricus Culture #2')
culture2.set_attribute_value('Strain Used', 'Sulfolobus solfataricus strain 98/2')
culture2.set_attribute_value('Growth Temperature (°C)', 75.0)
culture2.set_attribute_value('Culture Volume (mL)', 1000.0)
culture2.set_attribute_value('pH', 2.8)
culture2.set_attribute_value('Growth Phase Complete', false)
disable_authorization_checks { culture2.save! }
puts 'Seeded bacterial culture sample 2.'

# Enzyme samples
enzyme1 = Sample.new(title: 'Phosphoglycerate Kinase')
enzyme1.sample_type = enzyme_sample_type
enzyme1.projects = [$project]
enzyme1.contributor = $guest_person
enzyme1.policy = Policy.create(name: 'default policy', access_type: 1)
enzyme1.set_attribute_value('Enzyme Name', 'Phosphoglycerate Kinase')
enzyme1.set_attribute_value('EC Number', 'EC 2.7.2.3')
enzyme1.set_attribute_value('Concentration (mg/mL)', 2.5)
enzyme1.set_attribute_value('Specific Activity (U/mg)', 125.0)
enzyme1.set_attribute_value('Storage Temperature (°C)', -20)
enzyme1.set_attribute_value('Purification Steps', 4)
disable_authorization_checks { enzyme1.save! }
puts 'Seeded enzyme sample 1.'

enzyme2 = Sample.new(title: 'Glyceraldehyde-3-phosphate Dehydrogenase')
enzyme2.sample_type = enzyme_sample_type
enzyme2.projects = [$project]
enzyme2.contributor = $guest_person
enzyme2.policy = Policy.create(name: 'default policy', access_type: 1)
enzyme2.set_attribute_value('Enzyme Name', 'Glyceraldehyde-3-phosphate Dehydrogenase')
enzyme2.set_attribute_value('EC Number', 'EC 1.2.1.12')
enzyme2.set_attribute_value('Concentration (mg/mL)', 1.8)
enzyme2.set_attribute_value('Specific Activity (U/mg)', 89.3)
enzyme2.set_attribute_value('Storage Temperature (°C)', -20)
enzyme2.set_attribute_value('Purification Steps', 3)
disable_authorization_checks { enzyme2.save! }
puts 'Seeded enzyme sample 2.'

enzyme3 = Sample.new(title: 'Triose Phosphate Isomerase')
enzyme3.sample_type = enzyme_sample_type
enzyme3.projects = [$project]
enzyme3.contributor = $guest_person
enzyme3.policy = Policy.create(name: 'default policy', access_type: 1)
enzyme3.set_attribute_value('Enzyme Name', 'Triose Phosphate Isomerase')
enzyme3.set_attribute_value('EC Number', 'EC 5.3.1.1')
enzyme3.set_attribute_value('Concentration (mg/mL)', 3.2)
enzyme3.set_attribute_value('Specific Activity (U/mg)', 210.5)
enzyme3.set_attribute_value('Storage Temperature (°C)', -20)
enzyme3.set_attribute_value('Purification Steps', 2)
disable_authorization_checks { enzyme3.save! }
puts 'Seeded enzyme sample 3.'

enzyme4 = Sample.new(title: 'Fructose-1,6-bisphosphate Aldolase/Phosphatase')
enzyme4.sample_type = enzyme_sample_type
enzyme4.projects = [$project]
enzyme4.contributor = $guest_person
enzyme4.policy = Policy.create(name: 'default policy', access_type: 1)
enzyme4.set_attribute_value('Enzyme Name', 'Fructose-1,6-bisphosphate Aldolase/Phosphatase')
enzyme4.set_attribute_value('EC Number', 'EC 4.1.2.13')
enzyme4.set_attribute_value('Concentration (mg/mL)', 1.5)
enzyme4.set_attribute_value('Specific Activity (U/mg)', 67.8)
enzyme4.set_attribute_value('Storage Temperature (°C)', -20)
enzyme4.set_attribute_value('Purification Steps', 5)
disable_authorization_checks { enzyme4.save! }
puts 'Seeded enzyme sample 4.'

# Associate samples with the experimental assay
disable_authorization_checks do
  $exp_assay.samples = [culture1, culture2, enzyme1, enzyme2, enzyme3, enzyme4]
  $exp_assay.save!
end

# Associate sample types with the study
disable_authorization_checks do
  $study.sample_types = [culture_sample_type, enzyme_sample_type]
  $study.save!
end

# Store references for other seed files
$culture_sample_type = culture_sample_type
$enzyme_sample_type = enzyme_sample_type
$culture1 = culture1
$culture2 = culture2
$enzyme1 = enzyme1
$enzyme2 = enzyme2
$enzyme3 = enzyme3
$enzyme4 = enzyme4

puts 'Seeded sample types and samples - 2 sample types with 6 total samples.'
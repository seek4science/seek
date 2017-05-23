# Sample attribute types
count = SampleAttributeType.count
date_time_type = SampleAttributeType.find_or_initialize_by(title:'Date time')
date_time_type.update_attributes(base_type: Seek::Samples::BaseType::DATE_TIME, placeholder: 'January 1, 2015 11:30 AM')

date_type = SampleAttributeType.find_or_initialize_by(title:'Date')
date_type.update_attributes(base_type: Seek::Samples::BaseType::DATE, placeholder: 'January 1, 2015')

float_type = SampleAttributeType.find_or_initialize_by(title:'Float')
float_type.update_attributes(title: 'Real number') unless SampleAttributeType.where(title: 'Real number').first

real_type = SampleAttributeType.find_or_initialize_by(title:'Real number')
real_type.update_attributes(base_type: Seek::Samples::BaseType::FLOAT, placeholder: '3.6')

int_type = SampleAttributeType.find_or_initialize_by(title:'Integer')
int_type.update_attributes(base_type: Seek::Samples::BaseType::INTEGER, placeholder: '1')

link_type = SampleAttributeType.find_or_initialize_by(title:'Web link')
link_type.update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp(%w(http https)).to_s, placeholder: 'http://www.example.com')

email_type = SampleAttributeType.find_or_initialize_by(title:'Email address')
email_type.update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: RFC822::EMAIL.to_s, placeholder: 'someone@example.com')

text_type = SampleAttributeType.find_or_initialize_by(title:'Text')
text_type.update_attributes(base_type: Seek::Samples::BaseType::TEXT)

string_type = SampleAttributeType.find_or_initialize_by(title:'String')
string_type.update_attributes(base_type: Seek::Samples::BaseType::STRING)

chebi_type = SampleAttributeType.find_or_initialize_by(title:'CHEBI ID')
chebi_type.update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: 'CHEBI:[0-9]+', placeholder: 'CHEBI:1234')

bool_type = SampleAttributeType.find_or_initialize_by(title:'Boolean')
bool_type.update_attributes(base_type: Seek::Samples::BaseType::BOOLEAN)

strain_type = SampleAttributeType.find_or_initialize_by(title:'SEEK Strain')
strain_type.update_attributes(base_type: Seek::Samples::BaseType::SEEK_STRAIN)

seek_sample_type = SampleAttributeType.find_or_initialize_by(title:'SEEK Sample')
seek_sample_type.update_attributes(base_type: Seek::Samples::BaseType::SEEK_SAMPLE)

cv_type = SampleAttributeType.find_or_initialize_by(title:'Controlled Vocabulary')
cv_type.update_attributes(base_type: Seek::Samples::BaseType::CV)

uri_type = SampleAttributeType.find_or_initialize_by(title:'URI')
uri_type.update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp.to_s, placeholder: 'http://www.example.com/123')

puts "Seeded #{SampleAttributeType.count - count} sample attribute types"

# Sample types
count = SampleType.count

# Biosamples controlled vocabs
disable_authorization_checks do
  growth_type_cv = SampleControlledVocab.where(title: 'SysMO Cell Culture Growth Type').first_or_create!(
      sample_controlled_vocab_terms_attributes: [{ label: 'batch'}, { label: 'chemostat'}]
  )

  organism_part_cv = SampleControlledVocab.where(title: 'SysMO Sample Organism Part').first_or_create!(
      sample_controlled_vocab_terms_attributes: [{ label: 'Whole cell'}, { label: 'Membrane fraction'}]
  )

  biosample_type = SampleType.where(title: 'SysMO Biosample').first_or_create(
      project_ids: [Project.first.id],
      sample_attributes_attributes: [
          { title: 'Sample ID or name', sample_attribute_type: string_type, required: true, is_title: true },
          { title: 'Cell culture name', sample_attribute_type: string_type, required: true },
          { title: 'Cell culture lab identifier', sample_attribute_type: string_type },
          { title: 'Cell culture start date', sample_attribute_type: date_type },
          { title: 'Cell culture growth type', sample_attribute_type: cv_type, sample_controlled_vocab: growth_type_cv },
          { title: 'Cell culture comment', sample_attribute_type: text_type },
          { title: 'Cell culture provider name', sample_attribute_type: string_type },
          { title: 'Cell culture provider identifier', sample_attribute_type: string_type },
          { title: 'Cell culture strain', sample_attribute_type: strain_type, required: true },
          { title: 'Sample lab identifier', sample_attribute_type: string_type, required: true },
          { title: 'Sampling date', sample_attribute_type: date_type },
          { title: 'Age at sampling', sample_attribute_type: int_type, unit: Unit.find_by_symbol('s') },
          { title: 'Sample provider name', sample_attribute_type: string_type },
          { title: 'Sample provider identifier', sample_attribute_type: string_type },
          { title: 'Sample comment', sample_attribute_type: text_type },
          { title: 'Sample organism part', sample_attribute_type: cv_type, sample_controlled_vocab: organism_part_cv }
      ]
  )
end

puts "Seeded #{SampleType.count - count} sample types"

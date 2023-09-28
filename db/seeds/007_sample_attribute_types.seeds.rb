# Sample attribute types
count = SampleAttributeType.count
date_time_type = SampleAttributeType.find_or_initialize_by(title:'Date time')
date_time_type.update(base_type: Seek::Samples::BaseType::DATE_TIME, placeholder: 'January 1, 2015 11:30 AM')

date_type = SampleAttributeType.find_or_initialize_by(title:'Date')
date_type.update(base_type: Seek::Samples::BaseType::DATE, placeholder: 'January 1, 2015')

float_type = SampleAttributeType.find_or_initialize_by(title:'Float')
float_type.update(title: 'Real number') unless SampleAttributeType.where(title: 'Real number').first

real_type = SampleAttributeType.find_or_initialize_by(title:'Real number')
real_type.update(base_type: Seek::Samples::BaseType::FLOAT, placeholder: '3.6')

int_type = SampleAttributeType.find_or_initialize_by(title:'Integer')
int_type.update(base_type: Seek::Samples::BaseType::INTEGER, placeholder: '1')

link_type = SampleAttributeType.find_or_initialize_by(title:'Web link')
link_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp(%w(http https)).to_s, placeholder: 'http://www.example.com', resolution:'\\0')

email_type = SampleAttributeType.find_or_initialize_by(title:'Email address')
email_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: RFC822::EMAIL.to_s, placeholder: 'someone@example.com', resolution:'mailto:\\0')

text_type = SampleAttributeType.find_or_initialize_by(title:'Text')
text_type.update(base_type: Seek::Samples::BaseType::TEXT)

string_type = SampleAttributeType.find_or_initialize_by(title:'String')
string_type.update(base_type: Seek::Samples::BaseType::STRING)

chebi_type = SampleAttributeType.find_or_initialize_by(title:'ChEBI')
chebi_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: '^CHEBI:\\d+$', placeholder: 'CHEBI:1234', resolution:'http://identifiers.org/chebi/\\0')

ecn_type = SampleAttributeType.find_or_initialize_by(title:'ECN')
ecn_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: '[0-9\.]+', placeholder: '2.7.1.121',
                           resolution:'http://identifiers.org/brenda/\\0')

metanetx_chemical_type = SampleAttributeType.find_or_initialize_by(title:'MetaNetX chemical')
metanetx_chemical_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: 'MNXM\\d+', placeholder: 'MNXM01',
                                resolution:'http://identifiers.org/metanetx.chemical/\\0')

metanetx_reaction_type = SampleAttributeType.find_or_initialize_by(title:'MetaNetX reaction')
metanetx_reaction_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: 'MNXR\\d+', placeholder: 'MNXR891',
                                resolution:'http://identifiers.org/metanetx.reaction/\\0')

metanetx_compartment_type = SampleAttributeType.find_or_initialize_by(title:'MetaNetX compartment')
metanetx_compartment_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: 'MNX[CD]\\d+',
                                resolution:'http://identifiers.org/metanetx.compartment/\\0')

inchi_type = SampleAttributeType.find_or_initialize_by(title:'InChI')
inchi_type.update(base_type: Seek::Samples::BaseType::STRING,
                             regexp: '^InChI\\=1S?\\/[A-Za-z0-9\\.]+(\\+[0-9]+)?(\\/[cnpqbtmsih][A-Za-z0-9\\-\\+\\(\\)\\,\\/\\?\\;\\.]+)*$',
                             resolution:'http://identifiers.org/inchi/\\0')


bool_type = SampleAttributeType.find_or_initialize_by(title:'Boolean')
bool_type.update(base_type: Seek::Samples::BaseType::BOOLEAN)

strain_type = SampleAttributeType.find_or_initialize_by(title:'Registered Strain')
strain_type.update(base_type: Seek::Samples::BaseType::SEEK_STRAIN)

seek_sample_type = SampleAttributeType.find_or_initialize_by(title:'Registered Sample')
seek_sample_type.update(base_type: Seek::Samples::BaseType::SEEK_SAMPLE)

seek_sample_multi_type = SampleAttributeType.find_or_initialize_by(title:'Registered Sample (multiple)')
seek_sample_multi_type.update(base_type: Seek::Samples::BaseType::SEEK_SAMPLE_MULTI)

cv_type = SampleAttributeType.find_or_initialize_by(title:'Controlled Vocabulary')
cv_type.update(base_type: Seek::Samples::BaseType::CV)

uri_type = SampleAttributeType.find_or_initialize_by(title:'URI')
uri_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp.to_s, placeholder: 'http://www.example.com/123', resolution:'\\0')

doi_type = SampleAttributeType.find_or_initialize_by(title:'DOI')
doi_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: '(DOI:)?(.*)', placeholder: 'DOI:10.1109/5.771073', resolution:'https://doi.org/\\2')

ncbi_type = SampleAttributeType.find_or_initialize_by(title:'NCBI ID')
ncbi_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: '[0-9]+', placeholder: '23234', resolution:'https://identifiers.org/taxonomy/\\0')

data_file_type = SampleAttributeType.find_or_initialize_by(title: 'Registered Data file')
data_file_type.update(base_type: Seek::Samples::BaseType::SEEK_DATA_FILE)

ontology_type = SampleAttributeType.find_or_initialize_by(title:'Ontology')
ontology_type.update(base_type: Seek::Samples::BaseType::CV)

cv_list_type = SampleAttributeType.find_or_initialize_by(title:'Controlled Vocabulary List')
cv_list_type.update(base_type: Seek::Samples::BaseType::CV_LIST)

linked_custom_metadata_type = SampleAttributeType.find_or_initialize_by(title:'Linked Custom Metadata')
linked_custom_metadata_type.update(base_type: Seek::Samples::BaseType::LINKED_CUSTOM_METADATA)

linked_custom_metadata_multi_type = SampleAttributeType.find_or_initialize_by(title:'Linked Custom Metadata (multiple)')
linked_custom_metadata_multi_type.update(base_type: Seek::Samples::BaseType::LINKED_CUSTOM_METADATA_MULTI)

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

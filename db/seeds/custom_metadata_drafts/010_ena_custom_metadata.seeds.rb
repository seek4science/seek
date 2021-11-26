puts 'Seeded ENA Metadata'

# Initialisation of aliases for common sample attributes types, for easier use.

int_type = SampleAttributeType.find_or_initialize_by(title: 'Integer')
int_type.update_attributes(base_type: Seek::Samples::BaseType::INTEGER, placeholder: '1')

bool_type = SampleAttributeType.find_or_initialize_by(title: 'Boolean')
bool_type.update_attributes(base_type: Seek::Samples::BaseType::BOOLEAN)

float_type = SampleAttributeType.find_or_initialize_by(title: 'Real number')
float_type.update_attributes(base_type: Seek::Samples::BaseType::FLOAT, placeholder: '0.5')

date_type = SampleAttributeType.find_or_initialize_by(title: 'Date')
date_type.update_attributes(base_type: Seek::Samples::BaseType::DATE, placeholder: 'January 1, 2015')

string_type = SampleAttributeType.find_or_initialize_by(title: 'String')
string_type.update_attributes(base_type: Seek::Samples::BaseType::STRING)

cv_type = SampleAttributeType.find_or_initialize_by(title: 'Controlled Vocabulary')
cv_type.update_attributes(base_type: Seek::Samples::BaseType::CV)

text_type = SampleAttributeType.find_or_initialize_by(title: 'Text')
text_type.update_attributes(base_type: Seek::Samples::BaseType::TEXT, placeholder: '1')

# helper to create sample controlled vocab
def create_sample_controlled_vocab_terms_attributes(array)
  attributes = []
  array.each do |type|
    attributes << { label: type }
  end
  attributes
end

disable_authorization_checks do

  # seeds for sample controlled vocab

  # work package
  work_package_cv = SampleControlledVocab.where(title: 'ENA Workpackage').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['WP1', 'WP2', 'WP3', 'WP4',
                                                                                               'WP5', 'WP6'])
  )

  # status
  status_cv = SampleControlledVocab.where(title: 'ENA Status').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Public','Private'])
  )

  # sex
  sex_cv = SampleControlledVocab.where(title: 'Sex').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['male',
                                                                                               'female', 'undefined'])
  )

  # To add a new set of CV:
  # example_cv = SampleControlledVocab.where(title: 'CV Title').first_or_create!(
  #     sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['CV 1',
  #                                                                                                'CV 2', 'CV 3'])
  #   )
  #
  # Can later be used like that:
  # create_custom_metadata_attribute(title: 'CM Metadata attribute using CV', required: true, sample_attribute_type: cv_type,
  #                                        sample_controlled_vocab: example_cv),

  # Definition of the Custom Metadata types

  # Helper
  def create_custom_metadata_attribute(title:, required:, sample_attribute_type:, sample_controlled_vocab: nil)
    CustomMetadataAttribute.where(title).create!(title: title, required: required,
                                                 sample_attribute_type: sample_attribute_type,
                                                 sample_controlled_vocab: sample_controlled_vocab)
  end

  # Investigation
  CustomMetadataType.where(title: 'ENA Metadata Investigation', supported_type: 'Investigation').first_or_create!(
    title: 'ENA Metadata Investigation', supported_type: 'Investigation',
    custom_metadata_attributes: [
      # For "normal" sample_attribute_type:
      # create_custom_metadata_attribute(title: 'Internal Identifier', required: true, sample_attribute_type: text_type),
      # or, if the type does not have an alias:
      # create_custom_metadata_attribute(title: 'Organism Tax Id', required: true, sample_attribute_type: SampleAttributeType.where(title:'NCBI ID').first),
      #
      # "NCBI ID" is from the list of available sample_attribute_types (default listed there: https://docs.google.com/spreadsheets/d/1n7L-xcyyS9suIz-CFKYlUJSvaXjWfW0PaVumT6e6qjY/edit#gid=325725849)
      #
      # For Controlled Vocabulary:
      # if defined above:
      # create_custom_metadata_attribute(title: 'Work package', required: true, sample_attribute_type: cv_type,
      #                                        sample_controlled_vocab: work_package_cv),
      # if predefined:
      # create_custom_metadata_attribute(title: 'Work package', required: true, sample_attribute_type: cv_type,
      #                                        sample_controlled_vocab: SampleControlledVocab.where(title:'One predefined CV').first),

      create_custom_metadata_attribute(title: 'Internal Identifier', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Institution', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Work package', required: true, sample_attribute_type: cv_type,
                                       sample_controlled_vocab: work_package_cv),
      create_custom_metadata_attribute(title: 'Keywords', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Start Date', required: false, sample_attribute_type: date_type),
      create_custom_metadata_attribute(title: 'End Date', required: false, sample_attribute_type: date_type)
    ]
  )

  CustomMetadataType.where(title: 'ENA Metadata Study', supported_type: 'Study').first_or_create!(
    title: 'ENA Metadata Study', supported_type: 'Study',
    custom_metadata_attributes: [
      create_custom_metadata_attribute(title: 'Primary Accession', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Secondary Accession', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Short name', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Description', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Start Date', required: false, sample_attribute_type: date_type),
      create_custom_metadata_attribute(title: 'End Date', required: false, sample_attribute_type: date_type),
      create_custom_metadata_attribute(title: 'Submission Date', required: false, sample_attribute_type: date_type),
      create_custom_metadata_attribute(title: 'Factor', required: false, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Person(s) responsible', required: false, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Keywords', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Functional genome annotation', required: false, sample_attribute_type: bool_type),
      create_custom_metadata_attribute(title: 'Status', required: false, sample_attribute_type: cv_type, sample_controlled_vocab: status_cv)
    ]
  )

  CustomMetadataType.where(title: 'ENA Metadata Assay', supported_type: 'Assay').first_or_create!(
    title: 'ENA Metadata Assay', supported_type: 'Assay',
    custom_metadata_attributes: [
      create_custom_metadata_attribute(title: 'Unique Name Prefix', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Title', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Description', required: false, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Organism Tax Id', required: true, sample_attribute_type: SampleAttributeType.where(title:'NCBI ID').first),
      create_custom_metadata_attribute(title: 'Scientific Name', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Cell Type', required: false, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Tissue Type', required: true, sample_attribute_type: text_type),
      create_custom_metadata_attribute(title: 'Sex', required: false, sample_attribute_type: cv_type,
                                       sample_controlled_vocab: sex_cv),
      create_custom_metadata_attribute(title: 'Collection Date', required: false, sample_attribute_type: date_type),
      create_custom_metadata_attribute(title: 'Collected by', required: false, sample_attribute_type: text_type)
    ]
  )

end


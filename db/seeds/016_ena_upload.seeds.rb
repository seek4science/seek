# Custom Date dataType tailored to what ENA expects
ena_iso_date_type = SampleAttributeType.find_or_initialize_by(title: 'ENA collection date')
ena_iso_date_type.update(base_type: Seek::Samples::BaseType::STRING,
                         regexp: '^(?:[12]\d{3}(?:-(?:0[1-9]|1[0-2])(?:-(?:0[1-9]|[12]\d|3[01]))?)?(?:T\d{2}:\d{2}(?::\d{2})?Z?(?:[+-]\d{1,2})?)?(?:\/\d{4}-(?:\d{2}-(?:\d{2}(?:T\d{2}:\d{2}(?::\d{2})?Z?(?:[+-]\d{1,2})?)?)?)?)?)?$|^not collected$|^not provided$|^restricted access$|^missing: control sample$|^missing: sample group$|^missing: synthetic construct$|^missing: lab stock$|^missing: third party data$|^missing: data agreement established pre-2023$|^missing: endangered species$|^missing: human-identifiable$',
                         placeholder: '2015 or 2015-01 or 2015-01-01')

# General functionalities
def create_sample_controlled_vocab_terms_attributes(array)
  attributes = []
  array.each do |type|
    attributes << { label: type }
  end
  attributes
end

existing_study_types = ['Whole Genome Sequencing', 'Metagenomics', 'Transcriptome Analysis', 'Resequencing',
                        'Epigenetics', 'Synthetic Genomics', 'Forensic or Paleo-genomics', 'Gene Regulation Study',
                        'Cancer Genomics', 'Population Genomics', 'RNASeq', 'Exome Sequencing',
                        'Pooled Clone Sequencing', 'Transcriptome Sequencing', 'Other']

disable_authorization_checks do
  study_type_cv = SampleControlledVocab.where(title: 'ENA Study Types').first_or_create!(sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(existing_study_types))

  # Assay
  unless CustomMetadataType.where(title: 'ENA Study metadata', supported_type: 'Assay').any?
    cmt = CustomMetadataType.new(title: 'ENA Study metadata', supported_type: 'Assay')
    cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'study_type', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'Controlled Vocabulary'),
                                                                  sample_controlled_vocab: study_type_cv,
                                                                  description: 'The STUDY_TYPE presents a controlled vocabulary for expressing the overall purpose of the study.',
                                                                  label: 'ENA Study Type')
    cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'new_study_type', required: false,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'))
    cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'ENA study alias prefix', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'))
    cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'ENA experiment prefix', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'))
    cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'ENA sample alias prefix', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'))

    cmt.save!
  end
end
puts 'Seeded ENA custom metadata'
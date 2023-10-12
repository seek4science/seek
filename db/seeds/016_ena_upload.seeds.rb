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
  # Study
  unless ExtendedMetadataType.where(title: 'ENA Sample Metadata', supported_type: 'Study').any?
    study_emt = ExtendedMetadataType.new(title: 'ENA Sample Metadata', supported_type: 'Study')
    study_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'ena_sample_alias_prefix', required: true,
                                                                                sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                                                label: 'ENA sample alias prefix')
    study_emt.save!
  end

  study_type_cv = SampleControlledVocab.where(title: 'ENA Study Types').first_or_create!(sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(existing_study_types))

  # Assay
  unless ExtendedMetadataType.where(title: 'ENA Study metadata', supported_type: 'Assay').any?
    assay_cmt = ExtendedMetadataType.new(title: 'ENA Study metadata', supported_type: 'Assay')
    assay_cmt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'ena_study_title', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'), label: 'ENA study title',
                                                                  description: 'Title of the study as would be used in a publication.')
    assay_cmt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_type', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'Controlled Vocabulary'),
                                                                  sample_controlled_vocab: study_type_cv,
                                                                  description: 'The STUDY_TYPE presents a controlled vocabulary for expressing the overall purpose of the study.',
                                                                  label: 'ENA Study Type')
    assay_cmt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'new_study_type', required: false,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'), label: 'New Study Type',
                                                                  description: 'Specify a new Study Type here if "Other" was chosen as "ENA Study Type".')
    assay_cmt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'ena_study_abstract', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'Text'), label: 'ENA study abstract',
                                                                  description: 'Briefly describes the goals, purpose, and scope of the Study.  This need not be listed if it can be inherited from a referenced publication.')
    assay_cmt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'assay_stream', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                                  description: 'This is the name that will be transferred to the ISA JSON. Example: "My assay" will be defined as "a_my_assay.txt" in the ISA JSON',
                                                                  label: 'Name Assay Stream')
    assay_cmt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'ena_study_alias_prefix', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'), label: 'ENA study alias prefix')
    assay_cmt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'ena_experiment_alias_prefix', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'), label: 'ENA experiment alias prefix')
    assay_cmt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'ena_run_alias_prefix', required: true,
                                                                  sample_attribute_type: SampleAttributeType.find_by(title: 'String'), label: 'ENA run alias prefix')
    assay_cmt.save!
  end
end
puts 'Seeded ENA extended metadata'

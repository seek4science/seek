# frozen_string_literal: true

# HealthDCAT-AP COVID-19 Patient Registry example seed
# Demonstrates a DataFile with HealthDCAT-AP extended metadata,
# attached to a full Investigation → Study → Assay hierarchy.
#
# Run via:  bundle exec rake db:seed:extended_metadata_drafts:healthdcat_covid19_example

puts 'Seeding HealthDCAT-AP COVID-19 Patient Registry example...'

HDCAT_NS = 'http://healthdataportal.eu/ns/health#'
DPV_NS   = 'https://w3id.org/dpv#'
DCT_NS   = 'http://purl.org/dc/terms/'
DCAT_NS  = 'http://www.w3.org/ns/dcat#'

# ---------------------------------------------------------------------------
# Resolve common SampleAttributeTypes
# ---------------------------------------------------------------------------
string_type = SampleAttributeType.find_or_initialize_by(title: 'String')
string_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: '.*')

text_type = SampleAttributeType.find_or_initialize_by(title: 'Text')
text_type.update(base_type: Seek::Samples::BaseType::TEXT)

int_type = SampleAttributeType.find_or_initialize_by(title: 'Integer')
int_type.update(base_type: Seek::Samples::BaseType::INTEGER, placeholder: '1')

boolean_type = SampleAttributeType.find_or_initialize_by(title: 'Boolean')
boolean_type.update(base_type: Seek::Samples::BaseType::BOOLEAN)

linked_emt_type = SampleAttributeType.find_or_initialize_by(title: 'Linked Extended Metadata')
linked_emt_type.update(base_type: Seek::Samples::BaseType::LINKED_EXTENDED_METADATA)

# IRI string type (rdf_value_type: 'iri') — reuse existing URI SAT, ensure regexp is permissive
# and rdf_value_type is set so the RDF emitter produces RDF::URI objects.
iri_string_type = SampleAttributeType.find_or_initialize_by(title: 'URI - HealthDCAT')
iri_string_type.update(base_type: Seek::Samples::BaseType::STRING, regexp: '.*', rdf_value_type: 'iri')

disable_authorization_checks do
  # -------------------------------------------------------------------------
  # Inner EMT: Retention Period (maps to dct:PeriodOfTime blank node)
  # -------------------------------------------------------------------------
  unless ExtendedMetadataType.where(title: 'HealthDCAT Retention Period', supported_type: 'ExtendedMetadata').any?
    linked_emt = ExtendedMetadataType.new(title: 'HealthDCAT Retention Period', supported_type: 'ExtendedMetadata')
    linked_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'start_date', label: 'Start Date',
      pid: "#{DCAT_NS}startDate",
      sample_attribute_type: string_type
    )
    linked_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'end_date', label: 'End Date',
      pid: "#{DCAT_NS}endDate",
      sample_attribute_type: string_type
    )
    linked_emt.save!
    puts '  Created HealthDCAT Retention Period EMT'
  end

  retention_period_emt = ExtendedMetadataType.find_by(title: 'HealthDCAT Retention Period',
                                                      supported_type: 'ExtendedMetadata')

  # -------------------------------------------------------------------------
  # Outer EMT: HealthDCAT-AP Health Dataset (attached to DataFile)
  # -------------------------------------------------------------------------
  unless ExtendedMetadataType.where(title: 'HealthDCAT-AP Health Dataset', supported_type: 'DataFile').any?
    emt = ExtendedMetadataType.new(title: 'HealthDCAT-AP Health Dataset', supported_type: 'DataFile')

    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'health_category', label: 'Health Category',
      description: 'IRI of a health domain category (ICD-10, ICD-11, SNOMED CT, EU health-categories authority table)',
      pid: "#{HDCAT_NS}healthCategory",
      sample_attribute_type: iri_string_type
    )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'population_coverage', label: 'Population Coverage',
      description: 'Description of the population covered by the dataset',
      pid: "#{HDCAT_NS}populationCoverage",
      sample_attribute_type: text_type
    )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'min_typical_age', label: 'Minimum Typical Age',
      pid: "#{HDCAT_NS}minimumTypicalAge",
      sample_attribute_type: int_type
    )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'max_typical_age', label: 'Maximum Typical Age',
      pid: "#{HDCAT_NS}maximumTypicalAge",
      sample_attribute_type: int_type
    )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'number_of_records', label: 'Number of Records',
      pid: "#{HDCAT_NS}numberOfRecords",
      sample_attribute_type: int_type
    )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'trusted_data_holder', label: 'Trusted Data Holder',
      description: 'Whether this is a trusted data holder under EHDS',
      pid: "#{HDCAT_NS}trusteddataholder",
      sample_attribute_type: boolean_type
    )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'personal_data_categories', label: 'Personal Data Categories',
      description: 'Categories of personal data (dpv-pd: IRIs, e.g. https://w3id.org/dpv/dpv-pd#HealthRecord)',
      pid: "#{DPV_NS}hasPersonalData",
      sample_attribute_type: iri_string_type
    )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'access_rights', label: 'Access Rights',
      description: 'URI from EU Publications Office access-right vocabulary',
      pid: "#{DCT_NS}accessRights",
      sample_attribute_type: iri_string_type
    )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'retention_period', label: 'Retention Period',
      description: 'Time period during which the data is retained (start/end dates)',
      pid: "#{HDCAT_NS}retentionPeriod",
      sample_attribute_type: linked_emt_type,
      linked_extended_metadata_type: retention_period_emt
    )

    emt.save!
    puts '  Created HealthDCAT-AP Health Dataset EMT'
  end

  healthdcat_emt = ExtendedMetadataType.find_by(title: 'HealthDCAT-AP Health Dataset', supported_type: 'DataFile')

  # -------------------------------------------------------------------------
  # ISA hierarchy: Programme → Project → Investigation → Study → Assay
  # -------------------------------------------------------------------------
  next if DataFile.where(title: 'COVID-19 Patient Registry').any?

  person = Person.first || FactoryBot.create(:person)
  project = person.projects.first || person.projects.create!(title: 'HealthDCAT Example Project')

  investigation = Investigation.new(
    title: 'COVID-19 Clinical Research',
    description: 'Investigation into COVID-19 patient outcomes in hospitalised adults',
    projects: [project],
    contributor: person
  )
  investigation.policy = Policy.new(name: 'investigation policy', access_type: Policy::VISIBLE)
  investigation.save!

  study = Study.new(
    title: 'Hospitalised COVID-19 Patients Cohort',
    description: 'Observational cohort study of adults hospitalised with confirmed COVID-19',
    investigation: investigation,
    contributor: person
  )
  study.policy = Policy.new(name: 'study policy', access_type: Policy::VISIBLE)
  study.save!

  assay = Assay.new(
    title: 'Patient Registry Data Collection',
    description: 'Data collection assay for the COVID-19 patient registry',
    study: study,
    contributor: person,
    assay_class: AssayClass.for_type('EXP')
  )
  assay.policy = Policy.new(name: 'assay policy', access_type: Policy::VISIBLE)
  assay.save!

  # -------------------------------------------------------------------------
  # DataFile with HealthDCAT-AP extended metadata
  # -------------------------------------------------------------------------
  retention_em = ExtendedMetadata.new(extended_metadata_type: retention_period_emt)
  retention_em.set_attribute_value('start_date', '2020-03-01')
  retention_em.set_attribute_value('end_date', '2030-12-31')

  em = ExtendedMetadata.new(extended_metadata_type: healthdcat_emt)
  em.set_attribute_value('health_category',
                         'http://13.81.34.152:1101/resource/authority/healthcategories/INFECTIOUS_DISEASE')
  em.set_attribute_value('population_coverage',
                         'Adult hospitalised COVID-19 patients aged 18-65')
  em.set_attribute_value('min_typical_age', 18)
  em.set_attribute_value('max_typical_age', 65)
  em.set_attribute_value('number_of_records', 50_000)
  em.set_attribute_value('trusted_data_holder', true)
  em.set_attribute_value('personal_data_categories', 'https://w3id.org/dpv/dpv-pd#HealthRecord')
  em.set_attribute_value('access_rights',
                         'http://publications.europa.eu/resource/authority/access-right/RESTRICTED')
  em.set_attribute_value('retention_period', { 'start_date' => '2020-03-01', 'end_date' => '2030-12-31' })

  content_blob = ContentBlob.new(
    original_filename: 'covid19_registry.csv',
    content_type: 'text/csv'
  )

  data_file = DataFile.new(
    title: 'COVID-19 Patient Registry',
    description: 'Clinical data of hospitalised COVID-19 patients across European hospitals.',
    projects: [project],
    contributor: person,
    extended_metadata: em
  )
  data_file.policy = Policy.new(name: 'data file policy', access_type: Policy::VISIBLE)
  data_file.save!

  content_blob.asset = data_file
  content_blob.asset_version = data_file.version
  content_blob.save!

  data_file.assays << assay

  puts "  Created DataFile##{data_file.id} '#{data_file.title}'"
  puts 'HealthDCAT-AP COVID-19 example seeded successfully.'
end

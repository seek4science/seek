# This code seeds the starter templates in the database.
# To keep the link between parent and child template attributes, do not change the attribute titles !!!
# Changing the titles will replace the existing attributes with new ones instead of updating them.

# Custom upsert function for template attributes
# This will create a new template attribute if it does not exist, or update the existing one.
# This also assumes that a template_attribute is considered unique by its title and template_id.
# All other fields can be updated.
def upsert_template_attribute(title, template_id, **fields)
  template_attribute = TemplateAttribute.find_or_create_by(title:, template_id:)
  template_attribute.update(fields)
  template_attribute
end

# Source - ISA minimal starter template
source_template = Template.find_or_initialize_by(title: 'Source - ISA minimal starter template', level: 'study source',
                                                 group: 'ISA minimal starter')

source_temp_attributes = []
source_temp_attributes << upsert_template_attribute('Source Name',
                                                    source_template.id,
                                                    description: 'Sources are considered as the starting biological material used in a study.',
                                                    sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                    is_title: true,
                                                    required: true,
                                                    isa_tag: IsaTag.find_by(title: 'source')
)

source_temp_attributes << upsert_template_attribute('Source Characteristic 1',
                                                    source_template.id,
                                                    description: 'A characteristic of the source.',
                                                    sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                    is_title: false,
                                                    required: true,
                                                    isa_tag: IsaTag.find_by(title: 'source_characteristic'))

disable_authorization_checks do
  source_template.update(group_order: 1,
                         temporary_name: '1_Source - ISA minimal starter template',
                         version: '1.0.0',
                         isa_config: 'isaconfig-default_v2015-07-02/studySample.xml',
                         repo_schema_id: 'none',
                         organism: 'any',
                         projects: [Project.find_or_create_by(title: 'Default Project')],
                         policy: Policy.public_policy,
                         template_attributes: source_temp_attributes)

  source_template.save
end

# Sample - ISA minimal starter template
sample_template = Template.find_or_initialize_by(title: 'Sample - ISA minimal starter template', level: 'study sample',
                                                 group: 'ISA minimal starter')

sample_temp_attributes = []
sample_temp_attributes << upsert_template_attribute('Input',
                                                    sample_template.id,
                                                    description: 'Registered Samples in the platform used as input for this protocol.',
                                                    sample_attribute_type: SampleAttributeType.find_by(title: 'Registered Sample List'),
                                                    is_title: false,
                                                    required: true)

sample_temp_attributes << upsert_template_attribute('Name of a protocol with samples as outputs',
                                                    sample_template.id,
                                                    description: 'Type of experimental step that generates samples as outputs from the study sources.',
                                                    sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                    is_title: false,
                                                    required: true,
                                                    isa_tag: IsaTag.find_by(title: 'protocol'))

sample_temp_attributes << upsert_template_attribute('Name of protocol parameter 1',
                                                    sample_template.id,
                                                    description: 'A parameter for the protocol.',
                                                    sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                    is_title: false,
                                                    required: true,
                                                    isa_tag: IsaTag.find_by(title: 'parameter_value'))

sample_temp_attributes << upsert_template_attribute('Sample Name',
                                                    sample_template.id,
                                                    description: 'Samples are considered as biological material sampled from sources and used in the study.',
                                                    sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                    is_title: true,
                                                    required: true,
                                                    isa_tag: IsaTag.find_by(title: 'sample'))

sample_temp_attributes << upsert_template_attribute('Sample Characteristic 1',
                                                    sample_template.id,
                                                    description: 'A characteristic of the sample.',
                                                    sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                    is_title: false,
                                                    required: true,
                                                    sample_controlled_vocab: nil,
                                                    isa_tag: IsaTag.find_by(title: 'sample_characteristic'))

disable_authorization_checks do
  sample_template.update(group_order: 2,
                         temporary_name: '2_Sample - ISA minimal starter template',
                         version: '1.0.0',
                         isa_config: 'isaconfig-default_v2015-07-02/studySample.xml',
                         isa_measurement_type: 'sample',
                         isa_protocol_type: 'protocol with samples as outputs collection',
                         repo_schema_id: 'none',
                         organism: 'any',
                         projects: [Project.find_or_create_by(title: 'Default Project')],
                         policy: Policy.public_policy,
                         template_attributes: sample_temp_attributes)

  sample_template.save
end

# Material output assay - ISA minimal starter template
material_template = Template.find_or_initialize_by(title: 'Material output assay - ISA minimal starter template',
                                                   level: 'assay - material', group: 'ISA minimal starter')

material_temp_attributes = []
material_temp_attributes << upsert_template_attribute('Input',
                                                      material_template.id,
                                                      description: 'Registered Samples in the platform used as input for this protocol.',
                                                      sample_attribute_type: SampleAttributeType.find_by(title: 'Registered Sample List'),
                                                      is_title: false,
                                                      required: true)

material_temp_attributes << upsert_template_attribute('Name of a protocol with material output',
                                                      material_template.id,
                                                      description: 'Type of assay or experimental step performed that generates a material output.',
                                                      sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                      is_title: false,
                                                      required: true,
                                                      isa_tag: IsaTag.find_by(title: 'protocol'))

material_temp_attributes << upsert_template_attribute('Name of protocol parameter 1',
                                                      material_template.id,
                                                      description: 'A parameter for the protocol.',
                                                      sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                      is_title: false,
                                                      required: true,
                                                      isa_tag: IsaTag.find_by(title: 'parameter_value'))

material_temp_attributes << upsert_template_attribute('Output material Name',
                                                      material_template.id,
                                                      description: 'Name of the major material output resulting from the application of the protocol.',
                                                      sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                      is_title: true,
                                                      required: true,
                                                      isa_tag: IsaTag.find_by(title: 'other_material'))

material_temp_attributes << upsert_template_attribute('Output material characteristic 1',
                                                      material_template.id,
                                                      description: 'Characteristic 1 of the output material.',
                                                      sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                      is_title: false,
                                                      required: true,
                                                      isa_tag: IsaTag.find_by(title: 'other_material_characteristic'))

disable_authorization_checks do
  material_template.update(group_order: 3,
                           temporary_name: '3_Material output assay - ISA minimal starter template',
                           version: '1.0.0',
                           isa_config: 'none',
                           isa_measurement_type: 'any',
                           isa_technology_type: 'any',
                           isa_protocol_type: 'protocol with material output',
                           repo_schema_id: 'none',
                           organism: 'any',
                           projects: [Project.find_or_create_by(title: 'Default Project')],
                           policy: Policy.public_policy,
                           template_attributes: material_temp_attributes)

  material_template.save
end

# Data file output assay - ISA minimal starter template
data_file_template = Template.find_or_initialize_by(title: 'Data file output assay - ISA minimal starter template',
                                                    level: 'assay - data file', group: 'ISA minimal starter')

data_file_temp_attributes = []
data_file_temp_attributes << upsert_template_attribute('Input',
                                                       data_file_template.id,
                                                       description: 'Registered Samples in the platform used as input for this protocol.',
                                                       sample_attribute_type: SampleAttributeType.find_by(title: 'Registered Sample List'),
                                                       is_title: false,
                                                       required: true)

data_file_temp_attributes << upsert_template_attribute('Name of a protocol with data file output',
                                                       data_file_template.id,
                                                       description: 'Type of assay or experimental step performed that generates a data file output.',
                                                       sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                       is_title: false,
                                                       required: true,
                                                       isa_tag: IsaTag.find_by(title: 'protocol'))

data_file_temp_attributes << upsert_template_attribute('Name of protocol parameter 1',
                                                       data_file_template.id,
                                                       description: 'A parameter for the protocol.',
                                                       sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                       is_title: false,
                                                       required: true,
                                                       isa_tag: IsaTag.find_by(title: 'data_file_comment'))

data_file_temp_attributes << upsert_template_attribute('Data file Name',
                                                       data_file_template.id,
                                                       description: 'Name of the major data file output resulting from the application of the protocol.',
                                                       sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                       is_title: true,
                                                       required: true,
                                                       isa_tag: IsaTag.find_by(title: 'data_file'))

data_file_temp_attributes << upsert_template_attribute('Data file characteristic 1',
                                                       data_file_template.id,
                                                       description: 'Characteristic 1 of the data file output.',
                                                       sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                       is_title: false,
                                                       required: true,
                                                       isa_tag: IsaTag.find_by(title: 'data_file_comment'))

disable_authorization_checks do
  data_file_template.update(group_order: 4,
                            temporary_name: '4_Data file output assay - ISA minimal starter template',
                            version: '1.0.0',
                            isa_config: 'none',
                            isa_measurement_type: 'any',
                            isa_technology_type: 'any',
                            isa_protocol_type: 'protocol with data file output',
                            repo_schema_id: 'none',
                            organism: 'any',
                            projects: [Project.find_or_create_by(title: 'Default Project')],
                            policy: Policy.public_policy,
                            template_attributes: data_file_temp_attributes)

  data_file_template.save
end

puts 'Seeded minimal templates for organizing ISA JSON compliant experiments.'

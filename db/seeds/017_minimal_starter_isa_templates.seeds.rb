# Source - ISA minimal starter template
unless Template.where(title: 'Source - ISA minimal starter template', level: 'study source').any?
  source_template = Template.new(title: 'Source - ISA minimal starter template', level: 'study source')
else
  source_template = Template.where(title: 'Source - ISA minimal starter template', level: 'study source').first
end

source_temp_attributes = []
source_temp_attributes << TemplateAttribute.new(title: 'Source Name',
                                                description: 'Do not edit the name of this attribute. Sources are considered as the starting biological material used in a study.',
                                                sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                is_title: true,
                                                required: true,
                                                isa_tag: IsaTag.find_by(title: 'source'))

source_temp_attributes << TemplateAttribute.new(title: 'Source Characteristic 1',
                                                description: 'A characteristic of the source.',
                                                sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                is_title: false,
                                                required: false,
                                                isa_tag: IsaTag.find_by(title: 'source_characteristic'))

source_template.update(group: 'ISA minimal starter',
                       group_order: 1,
                       temporary_name: '1_Source - ISA minimal starter template',
                       version: '1.0.0',
                       isa_config: 'isaconfig-default_v2015-07-02/studySample.xml',
                       repo_schema_id: 'none',
                       organism: 'any',
                       projects: [Project.find_or_create_by(title: 'Default Project')],
                       policy: Policy.public_policy,
                       template_attributes: source_temp_attributes)

source_template.save

# Sample - ISA minimal starter template
unless Template.where(title: 'Sample - ISA minimal starter template', level: 'study sample').any?
  sample_template = Template.new(title: 'Sample - ISA minimal starter template', level: 'study sample')
else
  sample_template = Template.where(title: 'Sample - ISA minimal starter template', level: 'study sample').first
end

sample_temp_attributes = []
sample_temp_attributes << TemplateAttribute.new(title: 'Input',
                                                description: 'Registered Samples in the platform used as input for this protocol.',
                                                sample_attribute_type: SampleAttributeType.find_by(title: 'Registered Sample (multiple)'),
                                                is_title: false,
                                                required: true)

sample_temp_attributes << TemplateAttribute.new(title: 'Sample collection',
                                                description: 'Do not edit the name of this attribute. Type of assay or experimental step performed.',
                                                sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                is_title: false,
                                                required: true,
                                                isa_tag: IsaTag.find_by(title: 'protocol'))

sample_temp_attributes << TemplateAttribute.new(title: 'Name of protocol parameter 1',
                                                description: 'A parameter for the protocol.',
                                                sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                is_title: false,
                                                required: true,
                                                isa_tag: IsaTag.find_by(title: 'parameter_value'))

sample_temp_attributes << TemplateAttribute.new(title: 'Sample Name',
                                                description: 'Do not edit the name of this attribute. Samples are considered as biological material sampled from sources and used in the study.',
                                                sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                is_title: true,
                                                required: true,
                                                isa_tag: IsaTag.find_by(title: 'sample'))

sample_temp_attributes << TemplateAttribute.new(title: 'Sample Characteristic 1',
                                                description: 'A characteristic of the sample.',
                                                sample_attribute_type: SampleAttributeType.find_by(title: 'String'),
                                                is_title: false,
                                                required: true,
                                                sample_controlled_vocab: nil,
                                                isa_tag: IsaTag.find_by(title: 'sample_characteristic'))


sample_template.update(group: 'ISA minimal starter',
                       group_order: 1,
                       temporary_name: '1_Source - ISA minimal starter template',
                       version: '1.0.0',
                       isa_config: 'isaconfig-default_v2015-07-02/studySample.xml',
                       repo_schema_id: 'none',
                       organism: 'any',
                       projects: [Project.find_or_create_by(title: 'Default Project')],
                       policy: Policy.public_policy,
                       template_attributes: sample_temp_attributes)

sample_template.save


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

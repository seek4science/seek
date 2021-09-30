# Template
Factory.define(:template) do |f|
  f.sequence(:title) { |n| "Template #{n}" }
  f.with_project_contributor
end


Factory.define(:min_template, parent: :template) do |f|
  f.title 'A Minimal Template'
  f.after_build do |template|
    template.template_attributes << Factory.build(:template_attribute, title: 'full_name', sample_attribute_type: Factory(:full_name_sample_attribute_type), required: true, template: template)
  end
end

Factory.define(:max_template, parent: :template) do |f|
  f.title 'A Maximal Template'
  f.description 'A very new research'
  f.group 'arrayexpress'
  f.group_order 4
  f.temporary_name '4_arrayexpress_library_construction'
  f.template_version '1.2.0'
  f.isa_config 'genome_seq_default_v2015-07-02'
  f.isa_measurement_type 'transcription profiling'
  f.isa_technology_type 'transcription profiling'
  f.repo_schema_id 'transcription profiling'
  f.organism 'any'
  f.level 'assay'

  f.after_build do |template|
    template.template_attributes << Factory.build(:template_attribute, title: 'full_name', sample_attribute_type: Factory(:full_name_sample_attribute_type),
                 required: true, short_name: 'full_name short_name', description: 'full_name description', ontology_version:"1.1", template: template)
    template.template_attributes << Factory.build(:template_attribute, title: 'address', sample_attribute_type: Factory(:address_sample_attribute_type),
                 required: false, short_name: 'address short_name', description: 'address description', ontology_version:"2.1", template: template)
    template.template_attributes << Factory.build(:template_attribute, title: 'postcode', sample_attribute_type: Factory(:postcode_sample_attribute_type),
                 required: false, short_name: 'postcode short_name', description: 'postcode description', ontology_version:"4", template: template)
    template.template_attributes << Factory.build(:template_attribute, title: 'CAPITAL key', sample_attribute_type: Factory(:string_sample_attribute_type, title:'String'),
                 required: false, short_name: 'CAPITAL key short_name', description: 'CAPITAL key description', ontology_version:"v0.0.9", template: template)
  end
end

Factory.define(:apples_controlled_vocab_template, parent: :template) do |f|
  f.sequence(:title) { |n| "apples controlled vocab template #{n}" }
  f.after_build do |template|
    template.template_attributes << Factory.build(:apples_controlled_vocab_template_attribute, title: 'apples', required: true, template: template)
  end
end

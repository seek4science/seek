require 'test_helper'

class TemplateTest < ActiveSupport::TestCase

  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @project_ids = [@project.id]
    @source_characteristic_tag = ISATag.find_by(title: Seek::ISA::TagType::SOURCE_CHARACTERISTIC) || FactoryBot.create(:source_characteristic_isa_tag)

    @string_sample_attribute_type = SampleAttributeType.find_by(title:String) || FactoryBot.create(:string_sample_attribute_type)
  end

  test 'validation' do
    template = FactoryBot.build(:isa_source_template, projects: [@project], contributor: @person)
    assert template.valid?
    template.title = ''
    assert !template.valid?
    template.title = nil
    assert !template.valid?

    # do not allow empty projects
    template.title = 'Test'
    template.projects = []
    refute template.valid?

    template.project_ids = @project_ids
    assert template.valid?
  end

  test 'template level validation' do
    template = FactoryBot.build(:isa_source_template, projects: [@project], contributor: @person)
    assert template.valid?

    # Change the level to an invalid value
    template.level = 'My random template level'
    refute template.valid?
    assert_equal template.errors.map(&:attribute), [:level]
    assert_equal ["is not a valid #{t('template')} level"], template.errors.messages[:level]
  end

  test 'template should only have one title attribute' do
    template = FactoryBot.create(:isa_source_template,
                                 projects: [@project],
                                 contributor: @person)
    assert template.valid?

    # Try to add a second title attribute
    assert_difference('template.template_attributes.size', 1) do
      template.template_attributes << FactoryBot.build(:template_attribute, template: template,
                                                        title: 'Test',
                                                        is_title: true,
                                                        isa_tag: @source_characteristic_tag,
                                                        sample_attribute_type: @string_sample_attribute_type)
    end

    refute template.valid?
    assert_equal [:template_attributes], template.errors.map(&:attribute)
    assert_equal ["There must be 1 attribute which is the title, currently there are 2."], template.errors.messages[:template_attributes]
  end

  test 'all template attributes should have an ISA tag' do
    template = FactoryBot.build(:isa_source_template, projects: [@project], contributor: @person)
    assert template.valid?

    # Try to add an attribute without an ISA tag
    assert_difference('template.template_attributes.size', 1) do
      template.template_attributes << FactoryBot.build(:template_attribute, template: template,
                                                       title: 'Test',
                                                       is_title: false,
                                                       isa_tag: nil,
                                                       sample_attribute_type: @string_sample_attribute_type)
    end

    refute template.valid?
    assert_equal [:template_attributes], template.errors.map(&:attribute)
    assert_equal ["Attribute 'Test' is missing an ISA tag"], template.errors.messages[:template_attributes]
  end

  test 'ISA tags should be level-specific' do
    # Test 'study source' level - only 'source' and 'source_characteristic' ISA tags are allowed
    study_source_template = FactoryBot.build(:isa_source_template, projects: [@project], contributor: @person)
    assert study_source_template.valid?

    study_source_template.template_attributes << FactoryBot.build(:template_attribute, template: study_source_template,
                                                                    title: 'Sample Name',
                                                                    isa_tag: FactoryBot.create(:sample_isa_tag),
                                                                    sample_attribute_type: @string_sample_attribute_type)
    refute study_source_template.valid?
    assert_equal [:template_attributes], study_source_template.errors.map(&:attribute)
    assert_equal ["ISA Tag 'sample' for attribute 'Sample Name' is not allowed."], study_source_template.errors.messages[:template_attributes]

    # Test 'study sample' level - only 'input', 'sample', 'sample_characteristic', 'protocol' and 'parameter_value' ISA tags are allowed
    study_sample_template = FactoryBot.build(:isa_sample_collection_template, projects: [@project], contributor: @person)
    assert study_sample_template.valid?

    study_sample_template.template_attributes << FactoryBot.build(:template_attribute, template: study_sample_template,
                                                                    title: 'Source Name',
                                                                    isa_tag: FactoryBot.create(:source_isa_tag),
                                                                    sample_attribute_type: @string_sample_attribute_type)
    refute study_sample_template.valid?
    assert_equal [:template_attributes], study_sample_template.errors.map(&:attribute)
    assert_equal ["ISA Tag 'source' for attribute 'Source Name' is not allowed."], study_sample_template.errors.messages[:template_attributes]

    # Test 'assay - material' level - only 'input', 'other_material', 'other_material_characteristic', 'protocol' and 'parameter_value' ISA tags are allowed
    assay_material_template = FactoryBot.build(:isa_assay_material_template, projects: [@project], contributor: @person)
    assert assay_material_template.valid?

    assay_material_template.template_attributes << FactoryBot.build(:template_attribute, template: assay_material_template,
                                                                      title: 'Sample Name',
                                                                      isa_tag: FactoryBot.create(:sample_isa_tag),
                                                                      sample_attribute_type: @string_sample_attribute_type)
    refute assay_material_template.valid?
    assert_equal [:template_attributes], assay_material_template.errors.map(&:attribute)
    assert_equal ["ISA Tag 'sample' for attribute 'Sample Name' is not allowed."], assay_material_template.errors.messages[:template_attributes]

    # Test 'assay - data file' level - only 'input', 'data_file', 'data_file_comment', 'protocol' and 'parameter_value' ISA tags are allowed
    assay_data_file_template = FactoryBot.build(:isa_assay_data_file_template, projects: [@project], contributor: @person)
    assert assay_data_file_template.valid?

    assay_data_file_template.template_attributes << FactoryBot.build(:template_attribute, template: assay_data_file_template,
                                                                       title: 'Sample Name',
                                                                       isa_tag: FactoryBot.create(:sample_isa_tag),
                                                                       sample_attribute_type: @string_sample_attribute_type)
    refute assay_data_file_template.valid?
    assert_equal [:template_attributes], assay_data_file_template.errors.map(&:attribute)
    assert_equal ["ISA Tag 'sample' for attribute 'Sample Name' is not allowed."], assay_data_file_template.errors.messages[:template_attributes]
  end

  test 'correct occurrence of ISA tags' do
    # source ISA tag can only occur once
    source_template = FactoryBot.build(:isa_source_template, projects: [@project], contributor: @person)
    assert source_template.valid?
    source_template.template_attributes << FactoryBot.build(:template_attribute, template: source_template,
                                                              title: 'Second Source Name',
                                                              isa_tag: FactoryBot.create(:source_isa_tag),
                                                              sample_attribute_type: @string_sample_attribute_type)
    refute source_template.valid?
    assert_equal [:template_attributes], source_template.errors.map(&:attribute)
    assert_equal ["You must have exactly one attribute with a 'source' ISA Tag. Currently, 2 attributes found."], source_template.errors.messages[:template_attributes]

    # sample ISA tag can only occur once
    sample_template = FactoryBot.build(:isa_sample_collection_template, projects: [@project], contributor: @person)
    assert sample_template.valid?
    sample_template.template_attributes << FactoryBot.build(:template_attribute, template: sample_template,
                                                              title: 'Second Sample Name',
                                                              isa_tag: FactoryBot.create(:sample_isa_tag),
                                                              sample_attribute_type: @string_sample_attribute_type)
    refute sample_template.valid?
    assert_equal [:template_attributes], sample_template.errors.map(&:attribute)
    assert_equal ["You must have exactly one attribute with a 'sample' ISA Tag. Currently, 2 attributes found."], sample_template.errors.messages[:template_attributes]

    # input ISA tag can only occur once
    input_template = FactoryBot.build(:isa_sample_collection_template, projects: [@project], contributor: @person)
    assert input_template.valid?
    input_template.template_attributes << FactoryBot.build(:template_attribute, template: input_template,
                                                             title: 'Second Input',
                                                             isa_tag: FactoryBot.create(:input_isa_tag),
                                                             sample_attribute_type: FactoryBot.create(:sample_multi_sample_attribute_type))
    refute input_template.valid?
    assert_equal [:template_attributes], input_template.errors.map(&:attribute)
    assert_equal ["You must have exactly one attribute with a 'input' ISA Tag. Currently, 2 attributes found."], input_template.errors.messages[:template_attributes]

    # protocol ISA tag can only occur once
    protocol_template = FactoryBot.build(:isa_sample_collection_template, projects: [@project], contributor: @person)
    assert protocol_template.valid?
    protocol_template.template_attributes << FactoryBot.build(:template_attribute, template: protocol_template,
                                                                title: 'Second Protocol',
                                                                isa_tag: FactoryBot.create(:protocol_isa_tag),
                                                                sample_attribute_type: @string_sample_attribute_type)
    refute protocol_template.valid?
    assert_equal [:template_attributes], protocol_template.errors.map(&:attribute)
    assert_equal ["You must have exactly one attribute with a 'protocol' ISA Tag. Currently, 2 attributes found."], protocol_template.errors.messages[:template_attributes]

    # other_material ISA tag can only occur once
    other_material_template = FactoryBot.build(:isa_assay_material_template, projects: [@project], contributor: @person)
    assert other_material_template.valid?
    other_material_template.template_attributes << FactoryBot.build(:template_attribute, template: other_material_template,
                                                                      title: 'Second Extract Name',
                                                                      isa_tag: FactoryBot.create(:other_material_isa_tag),
                                                                      sample_attribute_type: @string_sample_attribute_type)
    refute other_material_template.valid?
    assert_equal [:template_attributes], other_material_template.errors.map(&:attribute)
    assert_equal ["You must have exactly one attribute with a 'other_material' ISA Tag. Currently, 2 attributes found."], other_material_template.errors.messages[:template_attributes]

    # data_file ISA tag can only occur once
    data_file_template = FactoryBot.build(:isa_assay_data_file_template, projects: [@project], contributor: @person)
    assert data_file_template.valid?
    data_file_template.template_attributes << FactoryBot.build(:template_attribute, template: data_file_template,
                                                                 title: 'Second File Name',
                                                                 isa_tag: FactoryBot.create(:data_file_isa_tag),
                                                                 sample_attribute_type: @string_sample_attribute_type)
    refute data_file_template.valid?
    assert_equal [:template_attributes], data_file_template.errors.map(&:attribute)
    assert_equal ["You must have exactly one attribute with a 'data_file' ISA Tag. Currently, 2 attributes found."], data_file_template.errors.messages[:template_attributes]
  end

  test 'title attribute cannot be of type seek_sample_multi' do
    template = FactoryBot.build(:isa_source_template, projects: [@project], contributor: @person)
    assert template.valid?

    title_attribute = template.template_attributes.detect(&:is_title)
    title_attribute.sample_attribute_type = FactoryBot.create(:sample_multi_sample_attribute_type)
    title_attribute.linked_sample_type = FactoryBot.create(:simple_sample_type)

    refute template.valid?
    assert_equal [:template_attributes], template.errors.map(&:attribute)
    assert_equal ["Attribute type of Seek sample multi can not be selected as the Template title."], template.errors.messages[:template_attributes]
  end

  test 'template attribute title uniqueness' do
    template = FactoryBot.build(:isa_source_template, projects: [@project], contributor: @person)
    assert template.valid?

    # Add an attribute whose title duplicates an existing one (case-insensitive)
    template.template_attributes << FactoryBot.build(:template_attribute, template: template,
                                                       title: 'source characteristic 1',
                                                       isa_tag: @source_characteristic_tag,
                                                       sample_attribute_type: @string_sample_attribute_type)

    refute template.valid?
    assert_equal [:template_attributes], template.errors.map(&:attribute)
    assert_equal ["Attribute names must be unique, there are duplicates of source characteristic 1"], template.errors.messages[:template_attributes]
  end
end

require 'test_helper'

class ExtendedMetadataAttributeTest < ActiveSupport::TestCase

  test 'initialize' do
    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type)
    assert_equal 'fish', attribute.title
    assert_equal 'Integer', attribute.sample_attribute_type.base_type
    refute attribute.required?

    attribute = ExtendedMetadataAttribute.new title: 'fish', required: true, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type)
    assert_equal 'fish', attribute.title
    assert_equal 'String', attribute.sample_attribute_type.base_type
    assert attribute.required?
  end

  test 'validate value - without required' do
    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type)
    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1')
    refute attribute.validate_value?('frog')
    refute attribute.validate_value?('1.1')
    refute attribute.validate_value?(1.1)
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type)
    assert attribute.validate_value?('funky fish 123')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    refute attribute.validate_value?(1)

    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type, regexp: 'yyy')
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')
    refute attribute.validate_value?(1)
    refute attribute.validate_value?('xxx')

    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:float_sample_attribute_type)
    assert attribute.validate_value?(1.0)
    assert attribute.validate_value?(1.2)
    assert attribute.validate_value?(0.78)
    assert attribute.validate_value?('0.78')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    refute attribute.validate_value?('fish')
    refute attribute.validate_value?('2 Feb 2015')

    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1')

    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:datetime_sample_attribute_type)
    assert attribute.validate_value?('2 Feb 2015')
    assert attribute.validate_value?('Thu, 11 Feb 2016 15:39:55 +0000')
    assert attribute.validate_value?('2016-02-11T15:40:14+00:00')
    assert attribute.validate_value?(DateTime.parse('2 Feb 2015'))
    assert attribute.validate_value?(DateTime.now)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?(1.2)
    refute attribute.validate_value?('30 Feb 2015')

    attribute = ExtendedMetadataAttribute.new(title: 'apple', sample_attribute_type: FactoryBot.create(:cv_list_attribute_type),
                                            sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), description: "apple samples", label: "apple samples")

    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')
    assert attribute.validate_value?([])
    assert attribute.validate_value?(['Granny Smith'])

    refute attribute.validate_value?('Granny Smith')
    refute attribute.validate_value?(['Peter','Granny Smith'])


  end

  test 'validate value with required' do
    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type), required: true
    assert attribute.validate_value?(1)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true
    assert attribute.validate_value?('string')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:float_sample_attribute_type), required: true
    assert attribute.validate_value?(1.2)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:datetime_sample_attribute_type), required: true
    assert attribute.validate_value?('9 Feb 2015')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = ExtendedMetadataAttribute.new(title: 'apple', required:true,
                                            sample_attribute_type: FactoryBot.create(:cv_list_attribute_type), sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), description: "apple samples", label: "apple samples")
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')
    refute attribute.validate_value?([])
    assert attribute.validate_value?(['Granny Smith'])

  end

  test 'validate value for linked extended metadata type' do

    attribute = ExtendedMetadataAttribute.new(title: 'role', sample_attribute_type: FactoryBot.create(:extended_metadata_sample_attribute_type),
                                            linked_extended_metadata_type: FactoryBot.create(:role_name_extended_metadata_type))

    assert attribute.linked_extended_metadata_type.extended_metadata_attributes.first.validate_value?('first name')
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.first.validate_value?('')
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.first.validate_value?(nil)
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.first.validate_value?([])


    assert attribute.linked_extended_metadata_type.extended_metadata_attributes.last.validate_value?('last name')
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.last.validate_value?(nil)
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.last.validate_value?('')
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.last.validate_value?([])



    attribute = ExtendedMetadataAttribute.new(title: 'study', sample_attribute_type: FactoryBot.create(:extended_metadata_sample_attribute_type),
                                            linked_extended_metadata_type: FactoryBot.create(:study_extended_metadata_type))


    # study_title required
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.first.validate_value?([])
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.first.validate_value?('')
    refute attribute.linked_extended_metadata_type.extended_metadata_attributes.first.validate_value?(nil)
    assert attribute.linked_extended_metadata_type.extended_metadata_attributes.first.validate_value?('study_title')



    study_sites_attr = attribute.linked_extended_metadata_type.extended_metadata_attributes.last


    # study_sites not required
    assert study_sites_attr.validate_value?([])
    assert study_sites_attr.validate_value?('')
    assert study_sites_attr.validate_value?(nil)

    study_site_name_attr = study_sites_attr.linked_extended_metadata_type.extended_metadata_attributes[0]
    study_site_location_attr = study_sites_attr.linked_extended_metadata_type.extended_metadata_attributes[1]
    participants_attr = study_sites_attr.linked_extended_metadata_type.extended_metadata_attributes[2]

    # study_site_name required
    refute study_site_name_attr.validate_value?('')
    refute study_site_name_attr.validate_value?(nil)
    refute study_site_name_attr.validate_value?([])
    assert study_site_name_attr.validate_value?('study_site_name')

    # study_site_location not required
    assert study_site_location_attr.validate_value?('')
    assert study_site_location_attr.validate_value?(nil)
    assert study_site_location_attr.validate_value?([])
    assert study_site_location_attr.validate_value?('study_site_location')

    # participants required
    refute participants_attr.validate_value?('')
    refute participants_attr.validate_value?(nil)
    refute participants_attr.validate_value?([])

    participant_name_attr = participants_attr.linked_extended_metadata_type.extended_metadata_attributes[0]
    first_name_attr = participant_name_attr.linked_extended_metadata_type.extended_metadata_attributes[0]
    last_name_attr = participant_name_attr.linked_extended_metadata_type.extended_metadata_attributes[1]

    # first_name required
    refute first_name_attr.validate_value?('')
    refute first_name_attr.validate_value?(nil)
    refute first_name_attr.validate_value?([])
    assert first_name_attr.validate_value?('first_name')

    # last_name required
    refute last_name_attr.validate_value?('')
    refute last_name_attr.validate_value?(nil)
    refute last_name_attr.validate_value?([])
    assert last_name_attr.validate_value?('first_name')

    participant_age_attr = participants_attr.linked_extended_metadata_type.extended_metadata_attributes[1]

    # participant_age not required
    assert participant_age_attr.validate_value?('')
    assert participant_age_attr.validate_value?(nil)
    assert participant_age_attr.validate_value?([])
    assert participant_age_attr.validate_value?('participant_age')


  end


  test 'accessor name' do
    attribute = ExtendedMetadataAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:datetime_sample_attribute_type)
    assert_equal 'fish', attribute.accessor_name

    attribute = ExtendedMetadataAttribute.new title: 'fish pie', sample_attribute_type: FactoryBot.create(:datetime_sample_attribute_type)
    assert_equal 'fish pie', attribute.accessor_name
  end

  test 'label defaults to humanized title' do
    attribute = ExtendedMetadataAttribute.new title: 'fish_soup', sample_attribute_type: FactoryBot.create(:datetime_sample_attribute_type)
    assert_nil attribute[:label]
    assert_equal 'Fish soup',attribute.label
    attribute.label = "Apple pie"
    assert_equal 'Apple pie',attribute.label
    assert_equal 'fish_soup',attribute.title

    attribute.label = nil
    attribute.title = nil

    assert_nil attribute.label

  end


end
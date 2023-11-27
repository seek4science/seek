require 'test_helper'

class SampleAttributeTypeTest < ActiveSupport::TestCase
  test 'valid?' do
    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::INTEGER)
    assert type.valid?
    assert_equal '.*', type.regexp

    type = SampleAttributeType.new(base_type: Seek::Samples::BaseType::INTEGER)
    refute type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: 'ActionPack')
    refute type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: 'Fish')
    refute type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::INTEGER, regexp: '[')
    refute type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::STRING, regexp: 'xxx')
    assert type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::CV)
    assert type.valid?
  end

  test 'default regexp' do
    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::INTEGER)
    type.save!
    type = SampleAttributeType.find(type.id)
    assert_equal '.*', type[:regexp]
  end

  test 'validate resolution' do
    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::STRING, regexp: '.*yyy')
    assert attribute.validate_resolution

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::STRING,
                                        regexp: '.*yyy', resolution:'\\0')
    assert attribute.validate_resolution

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::STRING,
                                        regexp: '.*yyy', resolution:'\\1')
    assert attribute.validate_resolution

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::STRING,
                                        regexp: '.*yyy', resolution:'fred')
    refute attribute.validate_resolution

  end

  test 'to json' do
    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::STRING, regexp: 'xxx')
    assert_equal %({"title":"x-type","base_type":"String","regexp":"xxx"}), type.to_json
  end

  test 'is_controlled_vocab?' do
    type = FactoryBot.create(:controlled_vocab_attribute_type)
    assert type.controlled_vocab?
    type = FactoryBot.create(:cv_list_attribute_type)
    assert type.controlled_vocab?
    type = FactoryBot.create(:text_sample_attribute_type)
    refute type.controlled_vocab?
    type = FactoryBot.create(:boolean_sample_attribute_type)
    refute type.controlled_vocab?
    type = FactoryBot.create(:sample_sample_attribute_type)
    refute type.controlled_vocab?
  end

  test 'is_seek_sample?' do
    type = FactoryBot.create(:sample_sample_attribute_type)
    assert type.seek_sample?
    type = FactoryBot.create(:sample_multi_sample_attribute_type)
    refute type.seek_sample?
    type = FactoryBot.create(:text_sample_attribute_type)
    refute type.seek_sample?
    type = FactoryBot.create(:boolean_sample_attribute_type)
    refute type.seek_sample?
    type = FactoryBot.create(:controlled_vocab_attribute_type)
    refute type.seek_sample?
  end

  test 'is_seek_data_file?' do
    type = FactoryBot.create(:data_file_sample_attribute_type)
    assert type.seek_data_file?
    type = FactoryBot.create(:sample_sample_attribute_type)
    refute type.seek_data_file?
    type = FactoryBot.create(:text_sample_attribute_type)
    refute type.seek_data_file?
    type = FactoryBot.create(:boolean_sample_attribute_type)
    refute type.seek_data_file?
    type = FactoryBot.create(:controlled_vocab_attribute_type)
    refute type.seek_data_file?
  end

  test 'isa_template_attributes' do
    type = FactoryBot.create(:age_sample_attribute_type)
    type2 = FactoryBot.create(:weight_sample_attribute_type)

    ta1 = FactoryBot.create(:template_attribute, sample_attribute_type: type)
    ta2 = FactoryBot.create(:template_attribute, sample_attribute_type: type)
    ta3 = FactoryBot.create(:template_attribute, sample_attribute_type: type)
    ta4 = FactoryBot.create(:template_attribute, sample_attribute_type: type2)

    type.reload
    template_attributes = type.isa_template_attributes
    assert_equal 3, template_attributes.count
    assert_includes template_attributes, ta1
    assert_includes template_attributes, ta2
    assert_includes template_attributes, ta3
    assert_not_includes template_attributes, ta4
  end
end

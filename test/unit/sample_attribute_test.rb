require 'test_helper'

class SampleAttributeTest < ActiveSupport::TestCase

  test 'sample_attribute initialize' do
    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:integer_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    assert_equal 'fish', attribute.title
    assert_equal 'Integer', attribute.sample_attribute_type.base_type
    refute attribute.required?
    refute attribute.is_title?

    attribute = SampleAttribute.new title: 'fish', required: true, is_title: true, sample_attribute_type: Factory(:string_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    assert_equal 'fish', attribute.title
    assert_equal 'String', attribute.sample_attribute_type.base_type
    assert attribute.required?
    assert attribute.is_title?
  end

  test 'it_title? overrides required?' do
    # if is_title? then required? is always true
    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:integer_sample_attribute_type),
                                    required: false, is_title: true,
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.required?
    assert attribute.is_title?

    attribute.save!
    attribute.reload

    assert attribute.required?
    assert attribute.is_title?
    assert attribute[:required]

    attribute = SampleAttribute.new title: 'fish', is_title: false, required: false, sample_attribute_type: Factory(:string_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    attribute.save!
    attribute.reload
    refute attribute.required?
    refute attribute.is_title?
    refute attribute[:required]
  end

  test 'valid?' do
    attribute = SampleAttribute.new title: 'fish',
                                    sample_attribute_type: Factory(:integer_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.valid?

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:string_sample_attribute_type, regexp: 'xxx'),
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.valid?

    attribute = SampleAttribute.new title: 'fish',
                                    sample_type: Factory(:simple_sample_type)
    refute attribute.valid?
    attribute = SampleAttribute.new sample_attribute_type: Factory(:integer_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    refute attribute.valid?
    attribute = SampleAttribute.new title: 'fish',
                                    sample_attribute_type: Factory(:integer_sample_attribute_type)
    refute attribute.valid?

    attribute = SampleAttribute.new title: 'fish', pid:'wibble',
                                    sample_attribute_type: Factory(:integer_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    refute attribute.valid?
    attribute.pid = 'http://somewhere.org#fish'
    assert attribute.valid?
    attribute.pid = 'dc:fish'
    assert attribute.valid?


    attribute = SampleAttribute.new
    refute attribute.valid?
  end

  test 'validate value - without required' do
    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:integer_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1')
    refute attribute.validate_value?('frog')
    refute attribute.validate_value?('1.1')
    refute attribute.validate_value?(1.1)
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:string_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.validate_value?('funky fish 123')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    refute attribute.validate_value?(1)

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:string_sample_attribute_type, regexp: 'yyy'),
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')
    refute attribute.validate_value?(1)
    refute attribute.validate_value?('xxx')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:float_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
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

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:datetime_sample_attribute_type),
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.validate_value?('2 Feb 2015')
    assert attribute.validate_value?('Thu, 11 Feb 2016 15:39:55 +0000')
    assert attribute.validate_value?('2016-02-11T15:40:14+00:00')
    assert attribute.validate_value?(DateTime.parse('2 Feb 2015'))
    assert attribute.validate_value?(DateTime.now)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?(1.2)
    refute attribute.validate_value?('30 Feb 2015')
  end

  test 'validate value with required' do
    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:integer_sample_attribute_type), required: true,
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.validate_value?(1)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:string_sample_attribute_type), required: true,
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.validate_value?('string')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:float_sample_attribute_type), required: true,
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.validate_value?(1.2)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: Factory(:datetime_sample_attribute_type), required: true,
                                    sample_type: Factory(:simple_sample_type)
    assert attribute.validate_value?('9 Feb 2015')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')
  end

  test 'accessor_name' do
    attribute = SampleAttribute.new title: 'fish pie'
    assert_equal 'fish pie', attribute.accessor_name

    attribute.title = "provider's cell culture identifier"
    assert_equal "provider's cell culture identifier", attribute.accessor_name

    attribute = SampleAttribute.new title: %(fish "' &-[]}^-pie)
    assert_equal %(fish "' &-[]}^-pie), attribute.accessor_name

    attribute = SampleAttribute.new title: 'Fish Pie'
    assert_equal 'Fish Pie', attribute.accessor_name

    attribute = SampleAttribute.new title: 'title'
    assert_equal 'title', attribute.accessor_name
  end

  test 'original accessor name is updated when title changes' do
    attribute = SampleAttribute.new title: 'fish pie'
    assert_equal 'fish pie', attribute.accessor_name
    assert_equal attribute.accessor_name, attribute.original_accessor_name

    attribute.title = 'title'
    assert_equal 'title', attribute.accessor_name
    assert_equal attribute.accessor_name, attribute.original_accessor_name

    attribute.title = 'updated_at'
    assert_equal 'updated_at', attribute.accessor_name
    assert_equal attribute.accessor_name, attribute.original_accessor_name

    attribute.title = 'HeLlo World!'
    assert_equal 'HeLlo World!', attribute.accessor_name
    assert_equal attribute.accessor_name, attribute.original_accessor_name
  end

  test 'title_attributes scope' do
    title = Factory(:sample_attribute, is_title: true, required: true, sample_attribute_type: Factory(:string_sample_attribute_type), sample_type: Factory(:simple_sample_type))
    not_title = Factory(:sample_attribute, is_title: false, required: true, sample_attribute_type: Factory(:string_sample_attribute_type), sample_type: Factory(:simple_sample_type))

    assert_includes SampleAttribute.title_attributes, title
    refute_includes SampleAttribute.title_attributes, not_title

    assert_includes title.sample_type.sample_attributes.title_attributes, title
    refute_includes not_title.sample_type.sample_attributes.title_attributes, not_title
  end

  test 'controlled vocab attribute factory' do
    # its a fairly complex factory so added test whilst creating it
    attribute = Factory(:apples_controlled_vocab_attribute, is_title: true, sample_type: Factory(:simple_sample_type))
    assert attribute.valid?
    refute_nil attribute.sample_controlled_vocab
    assert_equal 'CV', attribute.sample_attribute_type.base_type
    assert attribute.sample_attribute_type.controlled_vocab?
  end

  test 'controlled vocab validate value' do
    attribute = Factory(:apples_controlled_vocab_attribute, is_title: true, sample_type: Factory(:simple_sample_type))
    assert attribute.validate_value?('Granny Smith')
    refute attribute.validate_value?('Orange')
    refute attribute.validate_value?(1)
  end

  test 'controlled vocab must exist for CV type' do
    attribute = Factory(:apples_controlled_vocab_attribute, is_title: true, sample_type: Factory(:simple_sample_type))
    assert attribute.valid?
    attribute.sample_controlled_vocab = nil
    refute attribute.valid?
    attribute.sample_controlled_vocab = Factory(:apples_sample_controlled_vocab)
    assert attribute.valid?
  end

  test 'controlled vocab must not exist if not CV type' do
    attribute = Factory(:simple_string_sample_attribute, is_title: true, sample_type: Factory(:simple_sample_type))
    assert attribute.valid?
    attribute.sample_controlled_vocab = Factory(:apples_sample_controlled_vocab)
    refute attribute.valid?
  end

  test 'sample attribute factory' do
    attribute = Factory(:sample_sample_attribute, is_title: true, sample_type: Factory(:simple_sample_type))
    assert attribute.valid?
    refute_nil attribute.linked_sample_type
    assert attribute.linked_sample_type.is_a?(SampleType)
  end

  test 'linked sample type must exist for SeekSample type' do
    attribute = Factory(:sample_sample_attribute, is_title: true, sample_type: Factory(:simple_sample_type))
    assert attribute.valid?
    attribute.linked_sample_type = nil
    refute attribute.valid?
  end

  test 'linked sample type must not exist if not SeekSample type' do
    attribute = Factory(:simple_string_sample_attribute, is_title: true, sample_type: Factory(:simple_sample_type))
    assert attribute.valid?
    attribute.linked_sample_type = Factory(:simple_sample_type)
    refute attribute.valid?
  end

  test 'sample attribute validate value' do
    good_sample = Factory(:patient_sample)
    bad_sample = Factory(:sample)
    attribute = Factory(:sample_sample_attribute, is_title: true, sample_type: Factory(:simple_sample_type), linked_sample_type: good_sample.sample_type)

    assert valid_value?(attribute, good_sample.id)
    assert valid_value?(attribute, good_sample.id.to_s)
    # also ok with title
    assert valid_value?(attribute, good_sample.title)

    refute valid_value?(attribute, bad_sample.id)
    refute valid_value?(attribute, bad_sample.id.to_s)
    refute valid_value?(attribute, 'fish')
  end

  test 'samples linked via SeekSample must exist' do
    sample = Factory(:patient_sample)
    attribute = Factory(:sample_sample_attribute, required: true, sample_type: Factory(:simple_sample_type))
    attribute.linked_sample_type = sample.sample_type

    assert valid_value?(attribute, sample.title)
    refute valid_value?(attribute, 'surely no one has used this as a sample title')
  end

  test 'samples linked via SeekSample can be non-existant if field not required' do
    sample = Factory(:patient_sample)
    attribute = Factory(:sample_sample_attribute, required: false, sample_type: Factory(:simple_sample_type))
    attribute.linked_sample_type = sample.sample_type

    assert valid_value?(attribute, sample.title)
    assert valid_value?(attribute, 'surely no one has used this as a sample title')
  end

  test 'attribute with description and pid factory' do
    attribute = Factory(:string_sample_attribute_with_description_and_pid, is_title: true, sample_type: Factory(:simple_sample_type))
    assert attribute.valid?
    refute_nil attribute.description
    refute_nil attribute.pid
  end

  private

  def valid_value?(attribute, value)
    attribute.validate_value?(attribute.pre_process_value(value))
  end
end

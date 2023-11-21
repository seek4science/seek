require 'test_helper'

class SampleAttributeTest < ActiveSupport::TestCase

  test 'sample_attribute initialize' do
    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert_equal 'fish', attribute.title
    assert_equal 'Integer', attribute.sample_attribute_type.base_type
    refute attribute.required?
    refute attribute.is_title?

    attribute = SampleAttribute.new title: 'fish', required: true, is_title: true, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert_equal 'fish', attribute.title
    assert_equal 'String', attribute.sample_attribute_type.base_type
    assert attribute.required?
    assert attribute.is_title?
  end

  test 'it_title? overrides required?' do
    # if is_title? then required? is always true
    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type),
                                    required: false, is_title: true,
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.required?
    assert attribute.is_title?

    attribute.save!
    attribute.reload

    assert attribute.required?
    assert attribute.is_title?
    assert attribute[:required]

    attribute = SampleAttribute.new title: 'fish', is_title: false, required: false, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    attribute.save!
    attribute.reload
    refute attribute.required?
    refute attribute.is_title?
    refute attribute[:required]
  end

  test 'valid?' do
    attribute = SampleAttribute.new title: 'fish',
                                    sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.valid?

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type, regexp: 'xxx'),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.valid?

    attribute = SampleAttribute.new title: 'fish',
                                    sample_type: FactoryBot.create(:simple_sample_type)
    refute attribute.valid?
    attribute = SampleAttribute.new sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    refute attribute.valid?
    attribute = SampleAttribute.new title: 'fish',
                                    sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type)
    refute attribute.valid?

    attribute = SampleAttribute.new title: 'fish', pid:'wibble',
                                    sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    refute attribute.valid?

    attribute.pid = 'http://somewhere.org#fish'
    assert attribute.valid?
    attribute.pid = 'dc:fish'
    assert attribute.valid?


    attribute = SampleAttribute.new
    refute attribute.valid?
  end

  test 'auto strip pid' do
    attribute = SampleAttribute.new title: 'fish', pid:"   wibble:12\t  ",
                                    sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.valid?
    assert_equal 'wibble:12', attribute.pid
    attribute.pid = "  wibble:12\n "
    assert attribute.valid?
    assert_equal 'wibble:12', attribute.pid
  end

  test 'validate value - without required' do
    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1')
    refute attribute.validate_value?('frog')
    refute attribute.validate_value?('1.1')
    refute attribute.validate_value?(1.1)
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.validate_value?('funky fish 123')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    refute attribute.validate_value?(1)

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type, regexp: 'yyy'),
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')
    refute attribute.validate_value?(1)
    refute attribute.validate_value?('xxx')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:float_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
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

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:datetime_sample_attribute_type),
                                    sample_type: FactoryBot.create(:simple_sample_type)
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
    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:integer_sample_attribute_type), required: true,
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.validate_value?(1)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true,
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.validate_value?('string')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:float_sample_attribute_type), required: true,
                                    sample_type: FactoryBot.create(:simple_sample_type)
    assert attribute.validate_value?(1.2)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = SampleAttribute.new title: 'fish', sample_attribute_type: FactoryBot.create(:datetime_sample_attribute_type), required: true,
                                    sample_type: FactoryBot.create(:simple_sample_type)
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
    title = FactoryBot.create(:sample_attribute, is_title: true, required: true, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), sample_type: FactoryBot.create(:simple_sample_type))
    not_title = FactoryBot.create(:sample_attribute, is_title: false, required: true, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), sample_type: FactoryBot.create(:simple_sample_type))

    assert_includes SampleAttribute.title_attributes, title
    refute_includes SampleAttribute.title_attributes, not_title

    assert_includes title.sample_type.sample_attributes.title_attributes, title
    refute_includes not_title.sample_type.sample_attributes.title_attributes, not_title
  end

  test 'controlled vocab attribute factory' do
    # its a fairly complex factory so added test whilst creating it
    attribute = FactoryBot.create(:apples_controlled_vocab_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.valid?
    refute_nil attribute.sample_controlled_vocab
    assert_equal 'CV', attribute.sample_attribute_type.base_type
    assert attribute.sample_attribute_type.controlled_vocab?
  end

  test 'controlled vocab validate value' do
    attribute = FactoryBot.create(:apples_controlled_vocab_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.validate_value?('Granny Smith')
    refute attribute.validate_value?('Orange')
    refute attribute.validate_value?(1)
  end

  test 'controlled vocab validate value with allowed free text' do
    attribute = FactoryBot.create(:apples_controlled_vocab_attribute, is_title: true, allow_cv_free_text: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.validate_value?('Granny Smith')
    assert attribute.validate_value?('Orange')
    assert attribute.validate_value?(1)
  end

  test 'controlled vocab must exist for CV type' do
    attribute = FactoryBot.create(:apples_controlled_vocab_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.valid?
    attribute.sample_controlled_vocab = nil
    refute attribute.valid?
    attribute.sample_controlled_vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    assert attribute.valid?
  end

  test 'controlled vocab must not exist if not CV type' do
    attribute = FactoryBot.create(:simple_string_sample_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.valid?
    attribute.sample_controlled_vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    refute attribute.valid?
  end

  test 'list controlled vocab attribute factory' do
    attribute = FactoryBot.create(:apples_list_controlled_vocab_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.valid?
    refute_nil attribute.sample_controlled_vocab
    assert_equal 'CVList', attribute.sample_attribute_type.base_type
    assert attribute.sample_attribute_type.seek_cv_list?
  end

  test 'sample attribute factory' do
    attribute = FactoryBot.create(:sample_sample_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.valid?
    refute_nil attribute.linked_sample_type
    assert attribute.linked_sample_type.is_a?(SampleType)
  end

  test 'linked sample type must exist for SeekSample type' do
    attribute = FactoryBot.create(:sample_sample_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.valid?
    attribute.linked_sample_type = nil
    refute attribute.valid?
  end

  test 'linked sample type must not exist if not SeekSample type' do
    attribute = FactoryBot.create(:simple_string_sample_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.valid?
    attribute.linked_sample_type = FactoryBot.create(:simple_sample_type)
    refute attribute.valid?
  end

  test 'sample attribute validate value' do
    good_sample = FactoryBot.create(:patient_sample)
    bad_sample = FactoryBot.create(:sample)
    attribute = FactoryBot.create(:sample_sample_attribute, is_title: true, sample_type: FactoryBot.create(:simple_sample_type), linked_sample_type: good_sample.sample_type)

    assert valid_value?(attribute, good_sample.id)
    assert valid_value?(attribute, good_sample.id.to_s)
    # also ok with title
    assert valid_value?(attribute, good_sample.title)

    refute valid_value?(attribute, bad_sample.id)
    refute valid_value?(attribute, bad_sample.id.to_s)
    refute valid_value?(attribute, 'fish')
  end

  test 'samples linked via SeekSample must exist' do
    sample = FactoryBot.create(:patient_sample)
    attribute = FactoryBot.create(:sample_sample_attribute, required: true, sample_type: FactoryBot.create(:simple_sample_type))
    attribute.linked_sample_type = sample.sample_type

    assert valid_value?(attribute, sample.title)
    refute valid_value?(attribute, 'surely no one has used this as a sample title')
  end

  test 'samples linked via SeekSample can be non-existant if field not required' do
    sample = FactoryBot.create(:patient_sample)
    attribute = FactoryBot.create(:sample_sample_attribute, required: false, sample_type: FactoryBot.create(:simple_sample_type))
    attribute.linked_sample_type = sample.sample_type

    assert valid_value?(attribute, sample.title)
    assert valid_value?(attribute, 'surely no one has used this as a sample title')
  end

  test 'attribute with description and pid factory' do
    attribute = FactoryBot.create(:string_sample_attribute_with_description_and_pid, is_title: true, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.valid?
    refute_nil attribute.description
    refute_nil attribute.pid
  end

  test 'short pid' do
    attribute = FactoryBot.create(:string_sample_attribute_with_description_and_pid, is_title: true, pid: 'http://pid.org/attr#title', sample_type: FactoryBot.create(:simple_sample_type))
    assert_equal 'title',attribute.short_pid

    attribute = FactoryBot.create(:string_sample_attribute_with_description_and_pid, is_title: true, pid: 'pid:title', sample_type: FactoryBot.create(:simple_sample_type))
    assert_equal 'pid:title',attribute.short_pid

    attribute = FactoryBot.create(:string_sample_attribute_with_description_and_pid, is_title: true, pid: 'http://pid.org/attr/title', sample_type: FactoryBot.create(:simple_sample_type))
    assert_equal 'title',attribute.short_pid

    attribute = FactoryBot.create(:sample_sample_attribute, sample_type: FactoryBot.create(:simple_sample_type))
    assert_equal '', attribute.short_pid
  end

  test 'ontology_based?' do
    attribute = FactoryBot.create(:sample_sample_attribute, sample_type: FactoryBot.create(:simple_sample_type))
    refute attribute.ontology_based?

    attribute = FactoryBot.create(:simple_string_sample_attribute, sample_type: FactoryBot.create(:simple_sample_type))
    refute attribute.ontology_based?

    attribute = FactoryBot.create(:apples_controlled_vocab_attribute, sample_type: FactoryBot.create(:simple_sample_type))
    refute attribute.sample_controlled_vocab.ontology_based?
    refute attribute.ontology_based?

    attribute.sample_controlled_vocab = FactoryBot.create(:topics_controlled_vocab)
    assert attribute.sample_controlled_vocab.ontology_based?
    assert attribute.ontology_based?
  end

  test 'boolean' do
    bool_type = SampleAttributeType.new title: 'bool', base_type: Seek::Samples::BaseType::BOOLEAN
    attribute = FactoryBot.create(:sample_attribute, is_title: true, sample_attribute_type: bool_type, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.validate_value?(true)
    assert attribute.validate_value?(false)
    refute attribute.validate_value?('fish')
  end

  test 'chebi atribute' do
    type = SampleAttributeType.new title: 'CHEBI ID', regexp: 'CHEBI:[0-9]+', base_type: Seek::Samples::BaseType::STRING
    attribute = FactoryBot.create(:sample_attribute, is_title: true, sample_attribute_type: type, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.validate_value?('CHEBI:1111')
    assert attribute.validate_value?('CHEBI:1121')
    refute attribute.validate_value?('fish')
    refute attribute.validate_value?('fish:22')
    refute attribute.validate_value?('CHEBI:1121a')
    refute attribute.validate_value?('chebi:222')
  end

  test 'regular expression match' do
    # whole string must match
    type = SampleAttributeType.new(title: 'first name', base_type: Seek::Samples::BaseType::STRING, regexp: '[A-Z][a-z]+')
    attribute = FactoryBot.create(:sample_attribute, is_title: true, sample_attribute_type: type, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.validate_value?('Fred')
    refute attribute.validate_value?(' Fred')
    refute attribute.validate_value?('FRed')
    refute attribute.validate_value?('Fred2')
    refute attribute.validate_value?('Fred ')
  end

  test 'uri attribute type' do
    type = SampleAttributeType.new title: 'URI', base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp.to_s
    attribute = FactoryBot.create(:sample_attribute, is_title: true, sample_attribute_type: type, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.validate_value?('zzz:222')
    assert attribute.validate_value?('http://ontology.org#term')
    refute attribute.validate_value?('fish')
    refute attribute.validate_value?('fish;cow')
  end

  test 'validate text with newlines' do
    type = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::TEXT)
    attribute = FactoryBot.create(:sample_attribute, is_title: true, sample_attribute_type: type, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.validate_value?('fish\\n\\rsoup')
    assert attribute.validate_value?('fish\n\rsoup')
    assert attribute.validate_value?('fish\r\nsoup')
    assert attribute.validate_value?('   fish\n\rsoup ')
    str = %(with
  a
  new
  line%)
    assert attribute.validate_value?(str)
  end

  test 'validate_value' do
    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::STRING, regexp: 'xxx')
    attribute = FactoryBot.create(:sample_attribute, is_title: true, sample_attribute_type: type, sample_type: FactoryBot.create(:simple_sample_type))
    assert attribute.validate_value?('xxx')
    refute attribute.validate_value?('fish')
    refute attribute.validate_value?(nil)

    type = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::INTEGER)
    attribute.sample_attribute_type = type
    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1')
    assert attribute.validate_value?('01')
    refute attribute.validate_value?('frog')
    refute attribute.validate_value?('1.1')
    refute attribute.validate_value?(1.1)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    # contriversial, but after much argument decided to allow these values as integers
    assert attribute.validate_value?(1.0)
    assert attribute.validate_value?('1.0')
    assert attribute.validate_value?(1.00)
    assert attribute.validate_value?('1.00')
    assert attribute.validate_value?(1.000)
    assert attribute.validate_value?('1.000')
    assert attribute.validate_value?(2.0)
    assert attribute.validate_value?('2.0')

    type = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::STRING, regexp: '.*yyy')
    attribute.sample_attribute_type = type
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('happpp - yyy')
    refute attribute.validate_value?('')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?('xxx')

    type = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::TEXT, regexp: '.*yyy')
    attribute.sample_attribute_type = type
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('happpp - yyy')

    refute attribute.validate_value?('')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?('xxx')

    type = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::FLOAT)
    attribute.sample_attribute_type = type
    assert attribute.validate_value?(1.0)
    assert attribute.validate_value?(1.2)
    assert attribute.validate_value?(0.78)
    assert attribute.validate_value?('0.78')
    assert attribute.validate_value?(12.70)
    assert attribute.validate_value?('12.70')
    refute attribute.validate_value?('fish')
    refute attribute.validate_value?('2 Feb 2015')
    refute attribute.validate_value?(nil)

    assert attribute.validate_value?(1.0)
    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1.0')
    assert attribute.validate_value?('012')
    assert attribute.validate_value?('012.3')
    assert attribute.validate_value?('12.30')
    assert attribute.validate_value?('1')

    type = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::DATE_TIME)
    attribute.sample_attribute_type = type
    assert attribute.validate_value?('2 Feb 2015')
    assert attribute.validate_value?('Thu, 11 Feb 2016 15:39:55 +0000')
    assert attribute.validate_value?('2016-02-11T15:40:14+00:00')
    assert attribute.validate_value?(DateTime.parse('2 Feb 2015'))
    assert attribute.validate_value?(DateTime.now)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?(1.2)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('30 Feb 2015')

    type = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::DATE)
    attribute.sample_attribute_type = type
    assert attribute.validate_value?('2 Feb 2015')
    assert attribute.validate_value?('Thu, 11 Feb 2016 15:39:55 +0000')
    assert attribute.validate_value?('2016-02-11T15:40:14+00:00')
    assert attribute.validate_value?(Date.parse('2 Feb 2015'))
    assert attribute.validate_value?(Date.today)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?(1.2)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('30 Feb 2015')
  end

  test 'web and email regexp' do
    type = SampleAttributeType.new title: 'Email address', base_type: Seek::Samples::BaseType::STRING, regexp: RFC822::EMAIL.to_s
    attribute = FactoryBot.create(:sample_attribute, is_title: true, sample_attribute_type: type, sample_type: FactoryBot.create(:simple_sample_type))
    assert_equal RFC822::EMAIL.to_s, type.regexp

    assert attribute.validate_value?('fred@email.com')
    refute attribute.validate_value?('moonbeam')

    type = SampleAttributeType.new title: 'Web link', base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp(%w(http https)).to_s
    attribute.sample_attribute_type = type
    assert attribute.validate_value?('http://google.com')
    assert attribute.validate_value?('https://google.com')
    refute attribute.validate_value?('moonbeam')
  end

  private

  def valid_value?(attribute, value)
    attribute.validate_value?(attribute.pre_process_value(value))
  end
end

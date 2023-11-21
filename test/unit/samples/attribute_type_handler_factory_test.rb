require 'test_helper'

class AttributeTypeHandlerFactoryTest < ActiveSupport::TestCase
  def setup
    @factory = Seek::Samples::AttributeTypeHandlers::AttributeTypeHandlerFactory.instance
  end

  test 'handlers to for base type' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:simple_string_sample_attribute, sample_type: st)
    # they are repeated twice to check for any caching issues
    types = Seek::Samples::BaseType::ALL_TYPES + Seek::Samples::BaseType::ALL_TYPES
    types.each do |type|
      expected = "Seek::Samples::AttributeTypeHandlers::#{type}AttributeTypeHandler".constantize
      assert_kind_of expected, @factory.for_base_type(type, attr), "Expected #{expected.name} for #{type}"
    end
  end

  test 'for_base_type passes attribute' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:simple_string_sample_attribute, sample_type: st)
    type = @factory.for_base_type('SeekSample', attr)
    assert_equal attr, type.send(:attribute)
  end

  test 'exception for invalid type' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:simple_string_sample_attribute, sample_type: st)
    e = assert_raise(Seek::Samples::AttributeTypeHandlers::UnrecognisedAttributeHandlerType) do
      @factory.for_base_type('fish', attr)
    end
    assert_equal "unrecognised attribute base type 'fish'", e.message

    e = assert_raise(Seek::Samples::AttributeTypeHandlers::UnrecognisedAttributeHandlerType) do
      @factory.for_base_type('fish', attr)
    end
    assert_equal "unrecognised attribute base type 'fish'", e.message
  end
end

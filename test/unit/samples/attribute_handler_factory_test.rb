require 'test_helper'

class AttributeHandlerFactoryTest < ActiveSupport::TestCase
  def setup
    @factory = Seek::Samples::AttributeHandlers::AttributeHandlerFactory.instance
  end

  test 'handlers to for attribute' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:simple_string_sample_attribute, sample_type: st)
    # they are repeated twice to check for any caching issues
    types = Seek::Samples::BaseType::ALL_TYPES + Seek::Samples::BaseType::ALL_TYPES
    types.each do |type|
      attr.sample_attribute_type.base_type = type
      expected = "Seek::Samples::AttributeHandlers::#{type}AttributeHandler".constantize
      assert_kind_of expected, @factory.for_attribute(attr), "Expected #{expected.name} for #{type}"
    end
  end

  test 'exception for invalid type' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:simple_string_sample_attribute, sample_type: st)
    attr.sample_attribute_type.base_type = 'fish'
    e = assert_raise(Seek::Samples::AttributeHandlers::UnrecognisedAttributeHandler) do
      @factory.for_attribute(attr)
    end
    assert_equal "unrecognised attribute base type 'fish'", e.message
  end
end

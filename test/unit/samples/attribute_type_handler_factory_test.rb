require 'test_helper'

class AttributeTypeHandlerFactoryTest  < ActiveSupport::TestCase

  def setup
    @factory = Seek::Samples::AttributeTypeHandlers::AttributeTypeHandlerFactory.instance
  end

  test 'handlers to for base type' do
    #they are repeated twice to check for any caching issues
    types = Seek::Samples::BaseType::ALL_TYPES + Seek::Samples::BaseType::ALL_TYPES
    types.each do |type|
      expected = "Seek::Samples::AttributeTypeHandlers::#{type}AttributeTypeHandler".constantize
      assert_kind_of expected,@factory.for_base_type(type),"Expected #{expected.name} for #{type}"
    end
  end

  test 'passes additional options' do
    type = @factory.for_base_type('SeekSample',{fish:'soup'})
    options = type.send(:additional_options)
    assert_equal({fish: 'soup'},options)
  end

  test 'exception for invalid type' do
    assert_raise_with_message(Seek::Samples::AttributeTypeHandlers::UnrecognisedAttributeHandlerType, "unrecognised attribute base type 'fish'") do
      @factory.for_base_type('fish')
    end

    assert_raise_with_message(Seek::Samples::AttributeTypeHandlers::UnrecognisedAttributeHandlerType, "unrecognised attribute base type 'fish'") do
      @factory.for_base_type('fish')
    end
  end


end
require 'test_helper'

class BooleanAttributeTypeHandlerTest < ActiveSupport::TestCase

  test 'blank?' do
    handler = Seek::Samples::AttributeTypeHandlers::BooleanAttributeHandler.new({})

    assert handler.test_blank?(nil)
    assert handler.test_blank?('')
    refute handler.test_blank?(false)
    refute handler.test_blank?(true)
  end

end
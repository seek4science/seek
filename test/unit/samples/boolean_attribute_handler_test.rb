require 'test_helper'

class BooleanAttributeHandlerTest < ActiveSupport::TestCase

  test 'blank?' do
    handler = Seek::Samples::AttributeHandlers::BooleanAttributeHandler.new({})

    assert handler.test_blank?(nil)
    assert handler.test_blank?('')
    refute handler.test_blank?(false)
    refute handler.test_blank?(true)
  end

end
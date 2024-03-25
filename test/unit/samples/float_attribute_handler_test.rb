require 'test_helper'

class FloatAttributeHandlerTest < ActiveSupport::TestCase

  test 'convert' do
    handler = Seek::Samples::AttributeHandlers::FloatAttributeHandler.new({})

    assert_equal 2.7, handler.convert("2.7")
    assert_equal 2.0, handler.convert("2")
    assert_equal 2.0, handler.convert(2)
    assert_equal 3.5, handler.convert(3.5)

    assert_nil handler.convert(nil)
  end

end
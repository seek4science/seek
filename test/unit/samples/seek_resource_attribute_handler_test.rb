require 'test_helper'

class SeekResourceAttributeHandlerTest < ActiveSupport::TestCase

  test 'blank?' do
    handler = Seek::Samples::AttributeHandlers::SeekResourceAttributeHandler.new({})

    assert handler.test_blank?(nil)
    assert handler.test_blank?('')

    h=HashWithIndifferentAccess.new
    h['id']=nil
    h['title']=nil
    assert handler.test_blank?(h)
    h['id']=5
    refute handler.test_blank?(h)
    h['id']=nil
    h['title']='the title'
    refute handler.test_blank?(h)
  end


end
require 'test_helper'

class MimeTypesHelperTest < ActionView::TestCase
  include MimeTypesHelper
  
  SUPPORTED_TYPES=%w{application/excel application/msword application/octet-stream application/pdf application/vnd.excel application/vnd.ms-excel application/vnd.openxmlformats-officedocument.wordprocessingml.document application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.ms-powerpoint application/zip image/gif image/jpeg image/png text/plain text/x-comma-separated-values text/xml text/x-objcsrc}
  
  def test_recognised
    SUPPORTED_TYPES.each do |type|
      assert_not_equal "Unknown file type", mime_find(type)[:name],"Didn't recognise mime type #{type}"
    end
  end
  
  def test_not_recognised
    assert_equal "Unknown file type", mime_find("application/foobar-zoo-fish-squirrel")[:name]
  end
  
end
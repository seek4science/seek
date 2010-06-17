require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  
  fixtures :publications
  
  test "test uuid generated" do
    x = publications(:one)
    assert_nil x.attributes["uuid"]
    x.save    
    assert_not_nil x.attributes["uuid"]
  end
  
  test "uuid doesn't change" do
    x = publications(:one)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
end

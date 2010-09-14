require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  
  fixtures :all
  
  test "test uuid generated" do
    x = publications(:one)
    assert_nil x.attributes["uuid"]
    x.save    
    assert_not_nil x.attributes["uuid"]
  end
  
  test "title trimmed" do
    x = publications(:one)
    x.title=" a pub"
    x.save!
    assert_equal("a pub",x.title)
  end
  
  test "uuid doesn't change" do
    x = publications(:one)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
  
  def test_project_required
    p=Publication.new(:title=>"blah blah blah",:pubmed_id=>"123")
    assert !p.valid?
    p.project=projects(:sysmo_project)
    assert p.valid?
  end
  
end

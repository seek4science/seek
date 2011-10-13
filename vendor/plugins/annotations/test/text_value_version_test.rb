require File.dirname(__FILE__) + '/test_helper.rb'

class TextValueVersionTest < ActiveSupport::TestCase
  
  def test_text_value_version_class_loaded
    assert_kind_of TextValue::Version, TextValue::Version.new
  end
  
  def test_versioning_on_update
    ann = annotations(:bh_title_1)
    val = ann.value
    orig_content = val.text
    new_content = "Harry Potter IIIIIII"
    
    assert_kind_of TextValue, val
    
    # Check number of versions
    assert_equal 1, val.versions.length
    
    # Update the value and check that a version has been created
    
    val.text = new_content
    val.version_creator = users(:john)

    assert val.valid?
    
    assert val.save
    
    assert_equal 2, val.versions.length
    assert_equal new_content, val.text
    assert_equal 2, val.versions.latest.version
    assert_equal new_content, val.versions.latest.text
    assert_equal 1, val.versions.latest.previous.version
    assert_equal orig_content, val.versions.latest.previous.text
    assert_equal users(:john).id, val.version_creator_id
    assert_equal users(:john).id, val.versions.latest.version_creator_id
    assert_equal nil, val.versions.latest.previous.version_creator_id
  end
  
end
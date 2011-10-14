require File.dirname(__FILE__) + '/test_helper.rb'

class AnnotationVersionTest < ActiveSupport::TestCase
  
  def test_annotation_version_class_loaded
    assert_kind_of Annotation::Version, Annotation::Version.new
  end
  
  def test_versioning_on_update
    ann = annotations(:bh_title_1)
    orig_value_id = ann.value_id
    orig_content = ann.value_content
    new_content = "Harry Potter IIIIIII"
    
    # Check number of versions
    assert_equal 1, ann.versions.length
    
    # Update the value and check that a version has been created
    
    ann.value = new_content
    ann.version_creator = users(:john)

    assert ann.valid?
    
    assert ann.save
    
    assert_equal 2, ann.versions.length
    assert_equal new_content, ann.value_content
    assert_equal 2, ann.versions.latest.version
    assert_equal new_content, ann.versions.latest.value_content
    assert_equal 1, ann.versions.latest.previous.version
    assert_equal orig_content, ann.versions.latest.previous.value_content
    assert_equal orig_value_id, ann.versions.latest.previous.value_id
    assert_equal users(:john).id, ann.version_creator_id
    assert_equal users(:john).id, ann.versions.latest.version_creator_id
    assert_equal nil, ann.versions.latest.previous.version_creator_id
  end
  
end
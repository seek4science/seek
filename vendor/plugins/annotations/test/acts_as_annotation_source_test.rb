require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsAnnotationSourceTest < ActiveSupport::TestCase
  
  def test_has_many_annotations_association
    assert_equal 7, users(:john).annotations_by.length
    assert_equal 6, users(:jane).annotations_by.length
    assert_equal 3, groups(:sci_fi_geeks).annotations_by.length
    assert_equal 4, groups(:classical_fans).annotations_by.length
  end
  
  def test_annotations_by_class_method
    assert_equal 7, User.annotations_by(users(:john).id).length
    assert_equal 7, User.annotations_by(users(:john).id, true).length
    assert_equal 6, User.annotations_by(users(:jane).id).length
    assert_equal 6, User.annotations_by(users(:jane).id, true).length
    assert_equal 3, Group.annotations_by(groups(:sci_fi_geeks).id).length
    assert_equal 3, Group.annotations_by(groups(:sci_fi_geeks).id, true).length
    assert_equal 4, Group.annotations_by(groups(:classical_fans).id).length
    assert_equal 4, Group.annotations_by(groups(:classical_fans).id, true).length
  end
  
  def test_annotations_for_class_method
    assert_equal 4, User.annotations_for("Book", books(:h).id).length
    assert_equal 4, User.annotations_for("Book", books(:h).id, true).length
    assert_equal 1, User.annotations_for("Chapter", chapters(:bh_c10).id).length
    assert_equal 1, User.annotations_for("Chapter", chapters(:bh_c10).id, true).length
    assert_equal 1, Group.annotations_for("Book", books(:r).id).length
    assert_equal 1, Group.annotations_for("Book", books(:r).id, true).length
    assert_equal 1, Group.annotations_for("Chapter", chapters(:br_c2).id).length
    assert_equal 1, Group.annotations_for("Chapter", chapters(:br_c2).id, true).length
  end
  
  def test_latest_annotations_instance_method
    assert_equal 6, users(:jane).latest_annotations.length
    assert_equal 6, users(:jane).latest_annotations(nil, true).length
    assert_equal 3, groups(:sci_fi_geeks).latest_annotations.length
    assert_equal 3, groups(:sci_fi_geeks).latest_annotations(nil, true).length
    
    assert_equal 3, users(:john).latest_annotations(3).length
    assert_equal 3, users(:john).latest_annotations(3, true).length
  end
  
  def test_annotation_source_name_instance_method
    assert_equal "john", users(:john).annotation_source_name
    assert_equal "Classical Fans", groups(:classical_fans).annotation_source_name
  end
  
  def test_adding_of_annotation
    us = users(:jane)
    assert_equal 6, us.annotations_by.length
    ann1 = Annotation.new(:attribute_id => AnnotationAttribute.find_or_create_by_name("tag").id,
                          :annotatable_type => "Book", 
                          :annotatable_id => 1)
    ann1.value = "test"
    us.annotations_by << ann1 

    ann2 = Annotation.new(:attribute_name => "description",
                          :annotatable_type => "Book", 
                          :annotatable_id => 2)
    ann2.value = "test2"
    us.annotations_by << ann2 
                                           
    assert_not_nil(ann1)
    assert_not_nil(ann2)
    assert_equal 8, us.annotations_by(true).length
  end

  def test_annotations_by_hash_method
    user1 = users(:jane)
    expected_hash1 = {
      "Tag" => [ "programming", "wizadry" ],
      "Note" => "Remember to buy milk!",
      "Title" => [ "Ruby Hashes", "And It All Falls Down" ],
      "rating" => "4/5"
    }
    assert_equal expected_hash1, user1.annotations_by_hash

    user2 = User.create(:name => "Jim")
    expected_hash2 = { }
    assert_equal expected_hash2, user2.annotations_by_hash
  end
  
end

require File.dirname(__FILE__) + '/test_helper.rb'

class AnnotationAttributeTest < ActiveSupport::TestCase
  
  def test_annotation_attribute_class_loaded
    assert_kind_of AnnotationAttribute, AnnotationAttribute.new
  end
  
  def test has_many_annotations_association
    assert_equal 6, annotations_attributes(:aa_tag).annotations.length
    assert_equal 1, annotations_attributes(:aa_contextualtag).annotations.length
  end
  
  def test_add_duplicates
    assert_not_nil AnnotationAttribute.find_by_name("tag")
    
    assert_raise ActiveRecord::RecordInvalid do
      AnnotationAttribute.create!(:name => 'Tag')
    end
  end
  
end
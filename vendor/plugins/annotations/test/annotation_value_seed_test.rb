require File.dirname(__FILE__) + '/test_helper.rb'

class AnnotationValueSeedTest < ActiveSupport::TestCase
  
  def test_annotation_value_seed_class_loaded
    assert_kind_of AnnotationValueSeed, AnnotationValueSeed.new
  end
  
  def test_find_by_key
    assert_equal 10, AnnotationValueSeed.find_by_attribute_name("tag").length
    assert_equal 5, AnnotationValueSeed.find_by_attribute_name("Author").length
  end
  
end
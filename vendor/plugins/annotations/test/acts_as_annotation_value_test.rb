require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsAnnotationValueTest < ActiveSupport::TestCase
  
  # TODO: duplication tests!!
  
  def test_ann_content_setter
    val = Annotation.first.value
    
    new_content = "hellow world, testing test_ann_content_setter"
    
    val.ann_content = new_content
    
    assert_equal new_content, val.send(val.class.ann_value_content_field)
  end
  
end
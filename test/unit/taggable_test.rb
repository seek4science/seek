require 'test_helper'

class TaggableTest < ActiveSupport::TestCase

  test "tag_with" do
     p=Factory :person
     User.current_user = p.user
     assert_equal 0,p.expertise.size
     assert_difference("Annotation.count",2) do
       assert_difference("TextValue.count",2) do
         p.tag_with ["golf","fishing"],"expertise"
       end
     end
     p.reload
     assert_equal ["golf","fishing"].sort, p.expertise.collect{|t| t.text}.sort
  end

  test "tag_with_params" do
    p=Factory :person
     User.current_user = p.user
     assert_equal 0,p.expertise.size
     assert_difference("Annotation.count",2) do
       assert_difference("TextValue.count",2) do
         params={:expertise_autocompleter_selected_ids=>[],
                 :expertise_autocompleter_unrecognized_items=>["golf","fishing"]
         }
         p.tag_with_params params,"expertise"
       end
     end
     p.reload
     assert_equal ["golf","fishing"].sort, p.expertise.collect{|t| t.text}.sort
  end

  test "tag_with changed response" do
    p=Factory :person
    User.current_user = p.user
    p.save!
    attr="expertise"
    p.tag_with(["golf","fishing"],attr)
    p.save!
    assert !p.annotations_with_attribute(attr).empty?
    assert !p.tag_with(["golf","fishing"],attr)
    assert p.tag_with(["golf","fishing","sparrow"],attr)
    assert p.tag_with(["golf","fishing"],attr)
  end


end
require 'test_helper'

class TagsControllerTest< ActionController::TestCase
  include AuthenticatedTestHelper

  fixtures :all

  def setup
    login_as(:quentin)
  end

  test "show" do    
    get :show,:id=>tags(:fishing)
    assert_response :success
  end

  test "dont show duplicates for same tag for expertise and tools" do
    q=people(:pal)
    q.tool_list="zzzzz"
    q.expertise_list="zzzzz"
    q.save!
    q.reload
    assert_equal 1,q.expertise_counts.size,"should be 1 expertise tag"
    assert_equal 1,q.tool_counts.size,"should be 1 tools tag"
    tag=q.expertise_counts.first
    assert_equal "zzzzz",tag.name,"the expected tag name is zzzzz"
    get :show,:id=>tag.id
    assert_response :success
    assert_select "div.list_items_container" do
      assert_select "a",:text=>"A Pal",:count=>1
    end
  end


end
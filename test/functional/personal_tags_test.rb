require 'test_helper'

#tests related to people and tags, split from main PeopleControllerTest
class PersonalTagsTest < ActionController::TestCase


  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test "personal tags are shown" do
    person=people(:pal)
    assert person.user.owned_tags.collect(&:name).include?("cricket"), "This person must own the tag fishing for this test to work."
    tag=tags(:cricket)
    get :show,:id=>person
    assert :success
    assert_select "div#personal_tags a[href=?]",show_tag_path(tag),:text=>tag.name,:count=>1
  end

  test "tags_updated_correctly" do
    p=people(:aaron_person)
    p.expertise_list="one,two,three"
    p.tool_list="four"
    assert p.save
    assert_equal ["one","two","three"],p.expertise_list
    assert_equal ["four"],p.tool_list

    p=Person.find(p.id)
    assert_equal ["one","two","three"],p.expertise_list
    assert_equal ["four"],p.tool_list

    one=ActsAsTaggableOn::Tag.find(:first,:conditions=>{:name=>"one"})
    two=ActsAsTaggableOn::Tag.find(:first,:conditions=>{:name=>"two"})
    four=ActsAsTaggableOn::Tag.find(:first,:conditions=>{:name=>"four"})
    post :update, :id=>p.id, :person=>{}, :expertise_autocompleter_selected_ids=>[one.id,two.id],:tools_autocompleter_selected_ids=>[four.id],:tools_autocompleter_unrecognized_items=>"three"

    p=Person.find(p.id)

    assert_equal ["one","two"],p.expertise_list
    assert_equal ["four","three"],p.tool_list
  end

end
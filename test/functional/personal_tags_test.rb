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
    assert person.user.owned_tags.collect(&:name).include?("cricket"), "This person must own the tag cricket for this test to work."
    tag=tags(:cricket)
    get :show,:id=>person
    assert :success
    assert_select "div#personal_tags a[href=?]",show_tag_path(tag),:text=>tag.name,:count=>1
  end

  test "expertise and tools displayed correctly" do
    p=Factory :person
    Factory :expertise,:value=>"fishing",:source=>p,:annotatable=>p
    Factory :expertise,:value=>"bowling",:source=>p,:annotatable=>p
    Factory :tool,:value=>"spade",:source=>p,:annotatable=>p
    Factory :tool,:value=>"fishing",:source=>p,:annotatable=>p

    get :show,:id=>p
    assert_response :success

    assert_select "div#expertise" do
      assert_select "p#expertise" do
        assert_select "a",:text=>"fishing",:count=>1
        assert_select "a",:text=>"bowling",:count=>1
        assert_select "a",:text=>"spade",:count=>0
      end
      assert_select "p#tools" do
        assert_select "a",:text=>"spade",:count=>1
        assert_select "a",:text=>"fishing",:count=>1
        assert_select "a",:text=>"bowling",:count=>0
      end

    end
  end

  test "expertise and tools updated correctly" do
    p=people(:aaron_person)
    p.expertise = ["one","two","three"]
    p.tools = ["four"]
    assert p.save
    assert_equal ["one","three","two"],p.expertise.collect{|t| t.value.text }.sort
    assert_equal ["four"],p.tools.collect{|t| t.value.text}.sort

    p=Person.find(p.id)
    assert_equal ["one","three","two"],p.expertise.collect{|t| t.value.text }.sort
    assert_equal ["four"],p.tools.collect{|t| t.value.text}.sort

    expertise_annotations = p.expertise.sort_by{|e| e.value.text}
    one=expertise_annotations[0]
    two=expertise_annotations[2]
    three=expertise_annotations[1]
    four=p.tools.first
    post :update, :id=>p.id, :person=>{}, :expertise_autocompleter_selected_ids=>[one.id,two.id],:tools_autocompleter_selected_ids=>[four.id],:tools_autocompleter_unrecognized_items=>"three"
    assert_redirected_to p
    p=Person.find(p.id)

    assert_equal ["one","two"],p.expertise.collect{|t| t.value.text }.sort
    assert_equal ["four","three"],p.tools.collect{|t| t.value.text}.sort
  end

end
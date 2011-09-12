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
    p=Factory :person
    p2=Factory :person
    sop = Factory :sop,:contributor=>p
    cricket = Factory :tag,:annotatable=>sop,:source=>p.user,:value=>"cricket"
    frog = Factory :tag,:annotatable=>sop,:source=>p2.user,:value=>"frog"

    get :show,:id=>p
    assert :success

    assert_select "div#personal_tags a[href=?]",show_ann_path(cricket),:text=>"cricket",:count=>1
    assert_select "div#personal_tags a[href=?]",show_ann_path(frog),:text=>"frog",:count=>0
  end

  test "expertise and tools displayed correctly" do
    p=Factory :person
    fishing_exp=Factory :expertise,:value=>"fishing",:source=>p,:annotatable=>p
    bowling=Factory :expertise,:value=>"bowling",:source=>p,:annotatable=>p
    spade=Factory :tool,:value=>"spade",:source=>p,:annotatable=>p
    fishing_tool=Factory :tool,:value=>"fishing",:source=>p,:annotatable=>p

    get :show,:id=>p
    assert_response :success

    assert_select "div#expertise" do
      assert_select "p#expertise" do
        assert_select "a[href=?]",show_ann_path(fishing_exp),:text=>"fishing",:count=>1
        assert_select "a[href=?]",show_ann_path(bowling),:text=>"bowling",:count=>1
        assert_select "a",:text=>"spade",:count=>0
      end
      assert_select "p#tools" do
        assert_select "a[href=?]",show_ann_path(spade),:text=>"spade",:count=>1
        assert_select "a[href=?]",show_ann_path(fishing_tool),:text=>"fishing",:count=>1
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
    post :update, :id=>p.id, :person=>{}, :expertise_autocompleter_selected_ids=>[one.id,two.id],:tool_autocompleter_selected_ids=>[four.id],:tool_autocompleter_unrecognized_items=>"three"
    assert_redirected_to p
    p=Person.find(p.id)

    assert_equal ["one","two"],p.expertise.collect{|t| t.value.text }.sort
    assert_equal ["four","three"],p.tools.collect{|t| t.value.text}.sort
  end

  test "expertise and tools do not appear in personal tag cloud" do
    p = Factory :person
    login_as p.user

    exp=Factory :expertise,:source=>p.user,:annotatable=>p,:value=>"an_expertise"
    tool=Factory :tool,:source=>p.user,:annotatable=>p,:value=>"a_tool"
    tag=Factory :tag,:source=>p.user,:annotatable=>p,:value=>"a_tag"

    get :show,:id=>p
    assert :success

    assert_select "div#personal_tags a[href=?]",show_ann_path(tag),:text=>"a_tag",:count=>1
    assert_select "div#personal_tags a[href=?]",show_ann_path(tool),:text=>"a_tool",:count=>0
    assert_select "div#personal_tags a[href=?]",show_ann_path(exp),:text=>"an_expertise",:count=>0
  end

end
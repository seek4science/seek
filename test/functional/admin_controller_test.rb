require 'test_helper'

class AdminControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  test "visible to admin" do
    login_as(:quentin)
    get :show
    assert_response :success
    assert_nil flash[:error]
  end

  test "invisible to non admin" do
    login_as(:aaron)
    get :show
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "show graphs" do

    login_as(:quentin)
    get :graphs
    assert_response :success

  end

  test "editing tags visible to admin" do
    login_as(:quentin)
    get :tags
    assert_response :success

    get :edit_tag, :id=>tags(:fishing)
    assert_response :success
  end

  test "editing tags blocked for non admin" do
    login_as(:aaron)
    get :tags
    assert_redirected_to :root
    assert_not_nil flash[:error]


    get :edit_tag, :id=>tags(:fishing)
    assert_redirected_to :root
    assert_not_nil flash[:error]


    fishing_tag=tags(:fishing)
    post :edit_tag, :id=>fishing_tag,:tags_autocompleter_unrecognized_items=>"microbiology, spanish"
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :delete_tag, :id=>fishing_tag
    assert_redirected_to :root
    assert_not_nil flash[:error]

  end

  test "edit tag" do
    login_as(:quentin)
    person=people(:random_userless_person)
    person.tool_list="linux, ruby, fishing"
    person.expertise_list="fishing"
    person.save!

    assert_equal ["linux","ruby","fishing"],person.tool_list
    assert_equal ["fishing"], person.expertise_list

    fishing_tag=Tag.find(:first,:conditions=>{:name=>"fishing"})
    assert_not_nil fishing_tag

    golf_tag_id=tags(:golf).id
    post :edit_tag, :id=>fishing_tag,:tags_autocompleter_selected_ids=>[golf_tag_id],:tags_autocompleter_unrecognized_items=>"microbiology, spanish"
    assert_redirected_to :action=>:tags
    assert_nil flash[:error]

    person=Person.find(person.id)
    expected_tools=["golf","linux","ruby","microbiology","spanish"]
    expected_expertise=["golf","microbiology","spanish"]

    assert_equal expected_tools.size,person.tool_list.size
    assert_equal expected_expertise.size, person.expertise_list.size

    person.tool_list.each do |tool_tag|
      assert expected_tools.include?(tool_tag)
    end
    person.expertise_list.each do |expertise_tag|
      assert expected_expertise.include?(expertise_tag)
    end


    fishing_tag=Tag.find(:first,:conditions=>{:name=>"fishing"})
    assert_nil fishing_tag
    
  end

  test "delete_tag" do
    login_as(:quentin)
    
    person=people(:random_userless_person)
    person.tool_list="fishing"
    person.expertise_list="fishing"
    person.save!

    fishing_tag=Tag.find(:first,:conditions=>{:name=>"fishing"})
    assert_not_nil fishing_tag

    #must be a post
    get :delete_tag, :id=>fishing_tag
    assert_redirected_to :action=>:tags
    assert_not_nil flash[:error]

    fishing_tag=Tag.find(:first,:conditions=>{:name=>"fishing"})
    assert_not_nil fishing_tag

    post :delete_tag, :id=>fishing_tag
    assert_redirected_to :action=>:tags
    assert_nil flash[:error]

    fishing_tag=Tag.find(:first,:conditions=>{:name=>"fishing"})
    assert_nil fishing_tag

    person=Person.find(person.id)
    assert_equal [],person.tool_list
    assert_equal [],person.expertise_list
    
  end
  
end

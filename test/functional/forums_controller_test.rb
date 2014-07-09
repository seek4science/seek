require 'test_helper'

class ForumsControllerTest < ActionController::TestCase
  fixtures :all
  
  include AuthenticatedTestHelper
  
  def test_login_required_for_index
    get :index
    assert_response :redirect
    assert_redirected_to root_path
  end
  
  def test_index
    create_test_forums
    login_as(:quentin)
    get :index
    assert_response :success    
  end

  test "show forum" do
    forum = Factory(:forum)
    create_test_topics_for forum

    login_as(Factory(:user))
    get :show, :id => forum.id

    assert_response :success
    assert_nil flash[:error]
    assert_select "a", :text => /a topic/, :count => 5
  end

  test "should handle showing forum when topic owner is deleted" do
    forum = Factory(:forum)
    create_test_topics_for forum

    forum.topics.first.user.delete
    assert_nil forum.topics.first.user

    login_as(Factory(:user))
    get :show, :id => forum.id

    assert_response :success
    assert_nil flash[:error]
    assert_select "a", :text => /a topic/, :count => 5
  end

  test "should handle showing forum when replied_by_user of topic is deleted" do
    forum = Factory(:forum)
    create_test_topics_for forum

    assert forum.topics.select{|t| !t.replied_by_user.nil?}.empty?

    login_as(Factory(:user))
    get :show, :id => forum.id

    assert_response :success
    assert_nil flash[:error]
    assert_select "a", :text => /a topic/, :count => 5
  end

  test "get edit" do
    forum = Factory(:forum)
    login_as(Factory(:user))
    get :edit, :id => forum.id
    assert_response :success
  end

  test "should create forum" do
    login_as(Factory(:user))
    assert_difference('Forum.count',1) do
      post :create, :forum => {:name => 'a forum'}
    end
    forum = assigns(:forum)

    assert_redirected_to forum_path(forum)
    assert_nil flash[:error]
  end

  test "should update forum" do
    forum = Factory(:forum)
    assert_not_equal 'something', forum.name
    login_as(Factory(:user))

    put :update, :forum => {:name => 'something'}, :id => forum.id
    updated_forum = assigns(:forum)

    assert_redirected_to forum_path(updated_forum)
    assert_nil flash[:error]
    assert_equal 'something', updated_forum.name
  end

  test 'should destroy' do
    forum = Factory(:forum)
    topic = Factory(:topic, :forum => forum)

    login_as(Factory(:user))

    delete :destroy, :id => forum.id

    assert_redirected_to forums_path
    assert_nil flash[:error]
    assert_nil Forum.find_by_id(forum.id)
    assert_nil Topic.find_by_id(topic.id)
  end

  private
  def create_test_forums
    #create some post
    i = 0
    while i<5
      Factory(:forum)
      i += 1
    end
  end

  def create_test_topics_for forum
    #create some post
    i = 0
    while i<5
      Factory(:topic, :forum => forum)
      i += 1
    end
  end
end
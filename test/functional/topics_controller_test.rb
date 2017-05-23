require 'test_helper'

class TopicsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  setup do
    skip('Skipping forums tests for now')
  end

  test 'get index' do
    forum = Factory(:forum)
    create_test_topics_for forum
    get :index, forum_id: forum.id
    assert_redirected_to forum_path(forum.id)
    assert_nil flash[:error]
  end

  test 'should handle geting index when topic owner is deleted' do
    forum = Factory(:forum)
    create_test_topics_for forum
    # delete one owner
    Topic.first.user.delete
    assert_nil Topic.first.user

    get :index, forum_id: forum.id
    assert_redirected_to forum_path(forum.id)
    assert_nil flash[:error]
  end

  test 'show topic' do
    topic = Factory(:topic)
    create_test_posts_for topic
    get :show, id: topic.id, forum_id: topic.forum.id
    assert_response :success
    assert_nil flash[:error]
    assert_select 'p', text: /post body/, count: 5
  end

  test 'should handle showing topic when topic owner are deleted' do
    topic = Factory(:topic)
    create_test_posts_for topic
    # delete owner
    topic.user.delete
    topic.reload
    assert_nil topic.user

    get :show, id: topic.id, forum_id: topic.forum.id
    assert_response :success
    assert_nil flash[:error]
    assert_select 'p', text: /post body/, count: 5
  end

  test 'get edit' do
    topic = Factory(:topic)
    login_as(topic.user)
    get :edit, id: topic.id, forum_id: topic.forum.id
    assert_response :success
  end

  test 'should handle geting edit when topic owner is deleted' do
    topic = Factory(:topic)
    topic.user.delete
    topic.reload
    assert_nil topic.user

    login_as(:quentin)
    get :edit, id: topic.id, forum_id: topic.forum.id
    assert_response :success
  end

  test 'should create topic' do
    login_as(Factory(:user))
    forum = Factory(:forum)
    assert_difference('Topic.count', 1) do
      assert_difference('Post.count', 1) do
        post :create, topic: { title: 'a topic', body: 'topic body' }, forum_id: forum.id
      end
    end
    topic = assigns(:topic)

    assert_redirected_to forum_topic_path(forum, topic)
    assert_nil flash[:error]
  end

  test 'should update topic' do
    topic = Factory(:topic)
    assert_not_equal 'something', topic.title
    login_as(topic.user)

    put :update, topic: { title: 'something' }, id: topic.id, forum_id: topic.forum.id
    updated_topic = assigns(:topic)

    assert_redirected_to forum_topic_path(updated_topic.forum, updated_topic)
    assert_nil flash[:error]
    assert_equal 'something', updated_topic.title
  end

  test 'should handle updating topic when topic owner is deleted' do
    topic = Factory(:topic)
    topic.user.delete
    topic.reload
    assert_nil topic.user

    assert_not_equal 'something', topic.title
    login_as(:quentin)

    put :update, topic: { title: 'something' }, id: topic.id, forum_id: topic.forum.id
    updated_topic = assigns(:topic)

    assert_redirected_to forum_topic_path(updated_topic.forum, updated_topic)
    assert_nil flash[:error]
    assert_equal 'something', updated_topic.title
  end

  test 'should destroy' do
    topic = Factory(:topic)
    post = Factory(:post, topic: topic)
    login_as(topic.user)

    delete :destroy, id: topic.id, forum_id: topic.forum.id

    assert_redirected_to forum_path(topic.forum.id)
    assert_nil flash[:error]
    assert_nil Topic.find_by_id(topic.id)
    assert_nil Post.find_by_id(post.id)
  end

  test 'should handle destroying  when topic owner is deleted' do
    topic = Factory(:topic)
    post = Factory(:post, topic: topic)
    topic.user.delete
    topic.reload
    assert_nil topic.user

    login_as(:quentin)

    delete :destroy, id: topic.id, forum_id: topic.forum.id

    assert_redirected_to forum_path(topic.forum.id)
    assert_nil flash[:error]
    assert_nil Topic.find_by_id(topic.id)
    assert_nil Post.find_by_id(post.id)
  end

  private

  def create_test_topics_for(forum)
    # create some post
    i = 0
    while i < 5
      Factory(:topic, forum: forum)
      i += 1
    end
  end

  def create_test_posts_for(topic)
    # create some post
    i = 0
    while i < 5
      Factory(:post, topic: topic)
      i += 1
    end
  end
end

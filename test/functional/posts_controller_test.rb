require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  setup do
    skip('Skipping forums tests for now')
  end

  test 'get index' do
    create_test_posts
    get :index
    assert_response :success
  end

  test 'should handle geting index when post owner are deleted' do
    create_test_posts
    # delete one post owner
    Post.first.user.delete
    assert_nil Post.first.user

    get :index
    assert_response :success
  end

  test 'show post' do
    post = Factory(:post)
    get :show, id: post.id, topic_id: post.topic.id, forum_id: post.forum.id
    assert_redirected_to forum_topic_path(post.forum_id, post.topic_id)
    assert_nil flash[:error]
  end

  test 'should handle showing when post owner are deleted' do
    post = Factory(:post)
    post.user.delete
    post.reload
    assert_nil post.user

    get :show, id: post.id, topic_id: post.topic.id, forum_id: post.forum.id
    assert_redirected_to forum_topic_path(post.forum_id, post.topic_id)
    assert_nil flash[:error]
  end

  test 'get edit' do
    post = Factory(:post)
    login_as(post.user)
    get :edit, id: post.id, topic_id: post.topic.id, forum_id: post.forum.id
    assert_response :success
  end

  test 'should handle geting edit when post owner are deleted' do
    post = Factory(:post)
    post.user.delete
    post.reload
    assert_nil post.user

    login_as(:quentin)
    get :edit, id: post.id, topic_id: post.topic.id, forum_id: post.forum.id
    assert_response :success
  end

  test 'should create post' do
    login_as(Factory(:user))
    topic = Factory(:topic)
    assert_difference('Post.count', 1) do
      post :create, post: { body: 'something' }, topic_id: topic.id, forum_id: topic.forum.id
    end
    post = assigns(:post)

    assert_redirected_to forum_topic_path(forum_id: post.forum.id, id: post.topic.id, anchor: post.dom_id, page: '1')
    assert_nil flash[:error]
  end

  test 'should update post' do
    post = Factory(:post)
    assert_not_equal 'something', post.body
    login_as(post.user)

    put :update, post: { body: 'something' }, id: post.id, topic_id: post.topic.id, forum_id: post.forum.id
    updated_post = assigns(:post)

    assert_redirected_to forum_topic_path(forum_id: updated_post.forum.id, id: updated_post.topic.id, anchor: updated_post.dom_id, page: '1')
    assert_nil flash[:error]
    assert_equal 'something', updated_post.body
  end

  test 'should handle updating post when post owner is deleted' do
    post = Factory(:post)
    post.user.delete
    post.reload
    assert_nil post.user

    assert_not_equal 'something', post.body
    login_as(:quentin)

    put :update, post: { body: 'something' }, id: post.id, topic_id: post.topic.id, forum_id: post.forum.id
    updated_post = assigns(:post)

    assert_redirected_to forum_topic_path(forum_id: updated_post.forum.id, id: updated_post.topic.id, anchor: updated_post.dom_id, page: '1')
    assert_nil flash[:error]
    assert_equal 'something', updated_post.body
  end

  test 'should destroy' do
    post = Factory(:post)
    login_as(post.user)

    delete :destroy, id: post.id, topic_id: post.topic.id, forum_id: post.forum.id

    assert_redirected_to forum_path(post.forum.id)
    assert_nil flash[:error]
    assert_nil Post.find_by_id(post.id)
  end

  test 'should handle destroying  when post owner is deleted' do
    post = Factory(:post)
    post.user.delete
    post.reload
    assert_nil post.user

    login_as(:quentin)

    delete :destroy, id: post.id, topic_id: post.topic.id, forum_id: post.forum.id

    assert_redirected_to forum_path(post.forum.id)
    assert_nil flash[:error]
    assert_nil Post.find_by_id(post.id)
  end

  private

  def create_test_posts
    # create some post
    i = 0
    while i < 5
      Factory(:post)
      i += 1
    end
  end
end

require 'test_helper'

class PresentationsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as Factory(:user)
  end

  test "index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:presentations)
  end

  test "can create with valid url" do
    presentation_attrs = Factory.build(:presentation).attributes #.symbolize_keys(turn string key to symbol)
    presentation_attrs[:data_url] = "http://www.virtual-liver.de/images/logo.png"

    assert_difference "Presentation.count" do
      post :create,:presentation => presentation_attrs
    end
  end

  test "can create with local file" do
    presentation_attrs = Factory.build(:presentation,:contributor=>User.current_user).attributes #.symbolize_keys(turn string key to symbol)
    presentation_attrs[:data] = fixture_file_upload('files/file_picture.png')

    assert_difference "Presentation.count" do
      post :create,:presentation => presentation_attrs
    end
  end

  test "can edit" do
    presentation = Factory :presentation,:contributor=>User.current_user

    get :edit,:id => presentation
    assert_response :success
  end

  test "can update" do
    presentation = Factory :presentation,:contributor=>User.current_user
    post :update,:id=>presentation,:presentation=>{:title=>"updated"}
    assert_redirected_to presentation_path(presentation)
  end

  test "can show" do
    presentation = Factory :presentation,:contributor=>User.current_user
    get :show,:id=>presentation
    assert_response :success
  end

  test "can download" do
    p = Factory :presentation,:contributor=>User.current_user

    get :download,:id=>p
    assert_response :success
  end

  test "can upload new version with valid url" do
    presentation = Factory :presentation,:contributor=>User.current_user
    assert_equal "http://www.virtual-liver.de/images/logo.png",presentation.content_blob.url
    new_data_url = "http://www.virtual-liver.de/images/liver-illustration.png"
    assert_difference "presentation.version" do
       post :new_version,:id => presentation,:presentation=>{:data_url=>new_data_url}
       presentation.reload
    end
    assert_redirected_to presentation_path(presentation)
  end

  test "can upload new version with valid filepath" do
    #by default, valid data_url is provided by content_blob in Factory
    presentation = Factory :presentation,:contributor=>User.current_user
    presentation.content_blob.url = nil
    presentation.content_blob.data = fixture_file_upload("files/little_file.txt")
    presentation.reload

    new_file_path = fixture_file_upload("files/little_file_v2.txt")
    assert_difference "presentation.version" do
       post :new_version,:id => presentation,:presentation=>{:data=>new_file_path}
       presentation.reload
    end
    assert_redirected_to presentation_path(presentation)
  end


  test "cannot upload file with invalid url" do
    presentation_attrs = Factory.build(:presentation, :contributor=>User.current_user).attributes #.symbolize_keys(turn string key to symbol)
    presentation_attrs[:data_url] = "http://www.blah.de/images/logo.png"

    assert_no_difference "Presentation.count" do
     post :create, :presentation=>presentation_attrs
    end
    assert_not_nil flash[:error]
  end

  test "cannot upload new version with invalid url" do
    presentation = Factory :presentation,:contributor=>User.current_user
    assert_equal "http://www.virtual-liver.de/images/logo.png",presentation.content_blob.url
    new_data_url = "http://www.blah.de/images/liver-illustration.png"
    assert_no_difference "presentation.version" do
       post :new_version,:id => presentation,:presentation=>{:data_url=>new_data_url}
       presentation.reload
    end
    assert_not_nil flash[:error]
  end

  test "can destroy" do
    presentation = Factory :presentation,:contributor=>User.current_user
    content_blob_id = presentation.content_blob_id
     assert_difference("Presentation.count",-1) do
       delete :destroy,:id => presentation
     end
    assert_redirected_to presentations_path

    #data/url is still stored in content_blob
    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

#  test "can subscribe" do
#     presentation = Factory :presentation,:contributor=>User.current_user
#
#     presentation.contributor.person.set_default_subscriptions
#
#     presentation.save!
#
#     presentation.reload
#
#     subscriptions = []
#
#    subscriptions = Subscription.find(:all,:conditions => ["subscribable_id=?",presentation.id])
#    assert  !subscriptions.empty?
#
#  end


end

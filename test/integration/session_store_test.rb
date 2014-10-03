require "test_helper"

class SessionStoreTest < ActionController::IntegrationTest

  def setup
    login_as_test_user
  end

  test "should go back to the authorized page when access denied" do

    data_file = Factory :data_file, :contributor => User.current_user
    get "/data_files/#{data_file.id}", {}, {'HTTP_REFERER' => "http://www.example.com/data_files/#{data_file.id}"}
    assert_response :success

    logout "http://www.example.com/data_files/#{data_file.id}"
    assert_redirected_to data_file_path(data_file)
    get "/data_files/#{data_file.id}", {}, {'HTTP_REFERER' => "http://www.example.com/data_files/#{data_file.id}"}
    assert_not_nil flash[:error]
    assert_redirected_to data_files_path

    login_as_test_user
    assert_redirected_to data_file_path(data_file)
    get "/data_files/#{data_file.id}"
    assert_response :success
  end

  test "should go to last correctly visited page(except search) after login" do
    get "/forums"
    assert_response :success
    logout "http://www.example.com/forums"

    data_file = Factory :data_file, :contributor => User.current_user, :policy => Factory(:public_policy)
    get "/data_files/#{data_file.id}"
    assert_response :success

    login_as_test_user
    assert_redirected_to data_file_path(data_file)

  end


  private

  def test_user
    User.authenticate("test", "blah") || Factory(:user, :login => "test", :password => "blah")
  end

  def login_as_test_user
    User.current_user = test_user
    post "/session", :login => test_user.login, :password => "blah"
  end

  def logout referer
    delete "/session", {}, {'HTTP_REFERER' => referer}
    User.current_user = nil
  end
end
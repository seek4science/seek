require 'test_helper'

class StudiedFactorsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test "cannot edit factors studied for downloadable data file" do
    df=data_files(:downloadable_data_file)
    get :index,:data_file_id=>df.id
    assert_select 'img[title="Start editing"]',:count=>0
    assert_select 'div[id="edit_on"]',:count=>0
    assert_select 'div[id="edit_off"]',:count=>0
  end

  test "can edit factors studied for editable data file" do
    df=data_files(:editable_data_file)
    get :index,:data_file_id=>df.id
    assert_select 'img[title="Start editing"]',:count=>1
    assert_select 'div[id="edit_on"]',:count=>1
    assert_select 'div[id="edit_off"]',:count=>1
  end

end

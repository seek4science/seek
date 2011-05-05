require 'test_helper'

class StudiedFactorsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test "cannot edit factors studied for downloadable data file" do
    df=data_files(:downloadable_data_file)
    df.save
    get :index,{:data_file_id=>df.id, :version => df.version}
    assert_select 'img[title="Start editing"]',:count=>0
    assert_select 'div[id="edit_on"]',:count=>0
    assert_select 'div[id="edit_off"]',:count=>0
  end

  test "can edit factors studied for editable data file" do
    df=data_files(:editable_data_file)
    df.save
    get :index,{:data_file_id=>df.id, :version => df.version}
    assert_select 'img[title="Start editing"]',:count=>1
    assert_select 'div[id="edit_on"]',:count=>1
    assert_select 'div[id="edit_off"]',:count=>1
  end

  test 'should create the factor studied with the concentration of the compound' do
    df=data_files(:editable_data_file)
    mi = measured_items(:concentration)
    cp = compounds(:compound_with_title)
    unit = units(:gram)
    fs = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :studied_factor => fs, :data_file_id => df.id, :version => df.version, :compound_title => cp.title
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.compound, cp
    assert_equal fs.measured_item, mi
  end

  test 'should not create the factor studied with the concentration of no compound' do
    df=data_files(:editable_data_file)
    mi = measured_items(:concentration)
    unit = units(:gram)
    fs = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :studied_factor => fs, :data_file_id => df.id, :version => df.version, :compound_title => nil
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert !fs.valid?
  end
end

require 'test_helper'

class PublishingTest < ActionController::TestCase

  tests DataFilesController

  fixtures :all

  include AuthenticatedTestHelper
  
  def setup
    login_as(:datafile_owner)
    @object=data_files(:picture)
  end
  
  test "do publish" do
    df=data_file_for_publishing

    assert df.can_manage?,"The datafile must be manageable for this test to succeed"
    post :publish,:id=>df
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
  end

  test "do not publish if not can_manage?" do
    login_as(:quentin)
    df=data_file_for_publishing
    assert !df.can_manage?,"The datafile must not be manageable for this test to succeed"
    post :publish,:id=>df
    assert_redirected_to data_file_path(df)
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
  end

  test "get preview_publish" do
    df=data_file_for_publishing
    assert df.can_manage?,"The datafile must be manageable for this test to succeed"
    get :preview_publish, :id=>df
    assert_response :success
  end

  test "cannot get preview_publish when not manageable" do
    login_as(:quentin)
    df=data_file_for_publishing
    assert !df.can_manage?,"The datafile must not be manageable for this test to succeed"
    get :preview_publish, :id=>df
    assert_redirected_to data_file_path(df)
    assert flash[:error]
  end

  private

  def data_file_for_publishing
    owner = users(:datafile_owner)
    other_user = users(:quentin)
    assay = Factory :experimental_assay
    data_file = Factory :data_file, :contributor=>owner, :project=>owner.person.projects.first

    data_file
  end
  
end
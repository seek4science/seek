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
    df=data_with_isa
    assay=df.assays.first
    other_df=assay.data_file_masters.reject{|d|d==df}.first
    assert_not_nil assay,"There should be an assay associated"
    assert df.can_manage?,"The datafile must be manageable for this test to succeed"

    get :preview_publish, :id=>df
    assert_response :success

    assert_select "p > a[href=?]",data_file_path(df),:text=>/#{df.title}/,:count=>1
    assert_select "li.type_and_title",:text=>/Assay/,:count=>1 do
      assert_select "a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_Assay_#{assay.id}"
    end


    assert_select "li.type_and_title",:text=>/Data file/,:count=>1 do
      assert_select "a[href=?]",data_file_path(other_df),:text=>/#{other_df.title}/
    end
    assert_select "li.secondary",:text=>/Notify owner/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_DataFile_#{other_df.id}"
    end

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

  def data_file_for_publishing(owner=users(:datafile_owner))
    Factory :data_file, :contributor=>owner, :project=>owner.person.projects.first
  end

  def data_with_isa
    df = data_file_for_publishing
    other_user = users(:quentin)
    assay = Factory :experimental_assay, :contributor=>df.contributor.person
    other_persons_data_file = Factory :data_file, :contributor=>other_user, :project=>other_user.person.projects.first,:policy=>Factory(:policy, :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)
    assay.relate(df)
    assay.relate(other_persons_data_file)
    df
  end
  
end
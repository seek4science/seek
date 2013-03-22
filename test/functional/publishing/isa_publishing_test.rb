require 'test_helper'

class IsaPublishingTest < ActionController::TestCase

  tests DataFilesController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
    @object=data_files(:picture)
  end

  test "do isa_publish" do
    df=data_file_for_publishing

    assert df.can_publish?,"The datafile must be publishable for this test to succeed"
    post :isa_publish,:id=>df
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
  end

  test "do not isa_publish if not can_manage?" do
    login_as(:quentin)
    df=data_file_for_publishing
    assert !df.can_publish?,"The datafile must not be manageable for this test to succeed"
    post :isa_publish,:id=>df
    assert_redirected_to data_file_path(df)
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
  end

  test "get isa_publish redirected" do
    #This is useful because if you logout it redirects back to the current page.
    #If you just published something, that will do a get request to *Controller#isa_publish
    get :isa_publish
    assert_response :redirect
  end

  test "get isa_publishing_preview" do
    df=data_with_isa
    assay=df.assays.first
    study=assay.study
    investigation=study.investigation

    notifying_df=assay.data_file_masters.reject{|d|d==df}.first
    request_publishing_df = Factory(:data_file,
                                    :projects => Factory(:gatekeeper).projects,
                                    :contributor => users(:datafile_owner),
                                    :assays => [assay])

    assert_not_nil assay,"There should be an assay associated"
    assert df.can_publish?,"The datafile must be publishable for this test to succeed"
    assert !request_publishing_df.can_publish?,"The datafile must not be publishable for this test to succeed"
    assert request_publishing_df.can_manage?,"The datafile must be manageable for this test to succeed"
    assert !notifying_df.can_manage?,"The datafile must not be manageable for this test to succeed"

    get :isa_publishing_preview, :id=>df
    assert_response :success

    assert_select "p > a[href=?]",data_file_path(df),:text=>/#{df.title}/,:count=>1
    assert_select "li.type_and_title",:text=>/Assay/,:count=>1 do
      assert_select "a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_Assay_#{assay.id}"
    end


    assert_select "li.type_and_title",:text=>/Data file/,:count=>3 do
      assert_select "a[href=?]",data_file_path(df),:text=>/#{df.title}/
      assert_select "a[href=?]",data_file_path(request_publishing_df),:text=>/#{request_publishing_df.title}/
      assert_select "a[href=?]",data_file_path(notifying_df),:text=>/#{notifying_df.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_DataFile_#{df.id}"
    end
    assert_select "li.secondary",:text=>/Submit publishing request/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_DataFile_#{request_publishing_df.id}"
    end
    assert_select "li.secondary",:text=>/Notify owner/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_DataFile_#{notifying_df.id}"
    end

    assert_select "li.type_and_title",:text=>/Study/,:count=>1 do
      assert_select "a[href=?]",study_path(study),:text=>/#{study.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_Study_#{study.id}"
    end

    assert_select "li.type_and_title",:text=>/Investigation/,:count=>1 do
      assert_select "a[href=?]",investigation_path(investigation),:text=>/#{investigation.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_Investigation_#{investigation.id}"
    end

  end

  test "get isa_publishing_preview for already published items" do
    df=data_with_isa
    assay=df.assays.first

    published_df = Factory(:data_file,
                                    :policy => Factory(:public_policy),
                                    :contributor => users(:datafile_owner),
                                    :assays => [assay])

    assert published_df.is_published?,"The datafile must be already published for this test to succeed"

    get :isa_publishing_preview, :id=>df
    assert_response :success

    assert_select "li.type_and_title",:text=>/Data file/ do
      assert_select "a[href=?]",data_file_path(published_df),:text=>/#{published_df.title}/
    end
    assert_select "li.secondary",:text=>/This item is already published/
  end

  test "get isa_publishing_preview for the items that the publishing request was sent" do
    df=data_with_isa
    assay=df.assays.first

    waiting_for_approval_df = Factory(:data_file,
                           :policy => Factory(:all_sysmo_viewable_policy),
                           :projects => Factory(:gatekeeper).projects,
                           :contributor => users(:datafile_owner),
                           :assays => [assay])
    ResourcePublishLog.add_publish_log(ResourcePublishLog::WAITING_FOR_APPROVAL, waiting_for_approval_df)

    assert !waiting_for_approval_df.is_published?,"The datafile must not be published for this test to succeed"
    assert !waiting_for_approval_df.can_publish?,"The datafile must not be publishable for this test to succeed"
    assert waiting_for_approval_df.can_manage?,"The datafile must manageable for this test to succeed"
    assert !ResourcePublishLog.last_waiting_approval_log(waiting_for_approval_df).nil?,"The datafile must not be in the waiting_for_approval state for this test to succeed"

    get :isa_publishing_preview, :id=>df
    assert_response :success

    assert_select "li.type_and_title",:text=>/Data file/ do
      assert_select "a[href=?]",data_file_path(waiting_for_approval_df),:text=>/#{waiting_for_approval_df.title}/
    end
    assert_select "li.secondary",:text=>/You already submitted the publishing request for this item./
  end

  test "do isa_publish all" do
    df=data_with_isa
    assays=df.assays
    params={:publish=>{}}
    non_owned_assets=[]
    assays.each do |a|
      assert !a.is_published?,"This assay should not be public for the test to work"
      assert !a.study.is_published?,"This assays study should not be public for the test to work"
      assert !a.study.investigation.is_published?,"This assays investigation should not be public for the test to work"

      params[:publish]["Assay"]||={}
      params[:publish]["Assay"][a.id.to_s]="1"
      params[:publish]["Study"]||={}
      params[:publish]["Study"][a.study.id.to_s]="1"
      params[:publish]["Investigation"]||={}
      params[:publish]["Investigation"][a.study.investigation.id.to_s]="1"

      a.assets.collect{|a| a.parent}.each do |asset|
        assert !asset.is_published?,"This assays assets should not be public for the test to work"
        params[:publish][asset.class.name]||={}
        params[:publish][asset.class.name][asset.id.to_s]="1"
        non_owned_assets << asset unless asset.can_manage?
      end
    end

    assert !non_owned_assets.empty?, "There should be non manageable assets included in this test"

    assert_emails 1 do
      post :isa_publish,params.merge(:id=>df)
    end

    assert_response :success

    df.reload

    assert df.is_published?, "Datafile should now be published"
    df.assays.each do |assay|
      assert assay.is_published?
      assert assay.study.is_published?
      assert assay.study.investigation.is_published?
    end
    non_owned_assets.each {|a| assert !a.is_published?, "Non manageable assets should not have been published"}

  end

  test "do isa_publish some" do
    df=data_with_isa

    assays=df.assays

    params={:publish=>{}}
    non_owned_assets=[]
    assays.each do |a|
      assert !a.is_published?,"This assay should not be public for the test to work"
      assert !a.study.is_published?,"This assays study should not be public for the test to work"
      assert !a.study.investigation.is_published?,"This assays investigation should not be public for the test to work"


      params[:publish]["Assay"]||={}
      params[:publish]["Study"]||={}
      params[:publish]["Study"][a.study.id.to_s]="1"
      params[:publish]["Investigation"]||={}

      a.assets.collect{|a| a.parent}.each do |asset|
        assert !asset.is_published?,"This assays assets should not be public for the test to work"
        params[:publish][asset.class.name]||={}
        params[:publish][asset.class.name][asset.id.to_s]="1" if asset.can_manage?
        non_owned_assets << asset unless asset.can_manage?
      end
    end

    assert !non_owned_assets.empty?, "There should be non manageable assets included in this test"

    assert_emails 0 do
      post :isa_publish,params.merge(:id=>df)
    end

    assert_response :success

    df.reload

    assert df.is_published?, "Datafile should now be published"
    df.assays.each do |assay|
      assert !assay.is_published?, "The assay was not requested to be published"
      assert assay.study.is_published?
      assert !assay.study.investigation.is_published?, "The investigation was not requested to be published"
    end
    non_owned_assets.each {|a| assert !a.is_published?, "Non manageable assets should not have been published"}

  end

  test "handle request publishing for manageable but not publishable item" do
    df=data_with_isa
    request_publishing_df = Factory(:data_file,
                                    :projects => Factory(:gatekeeper).projects,
                                    :contributor => users(:datafile_owner),
                                    :assays => df.assays)

    params={:publish=>{}}

    assert !request_publishing_df.is_published?,"This data file should not be public for the test to work"
    params[:publish][request_publishing_df.class.name]||={}
    params[:publish][request_publishing_df.class.name][request_publishing_df.id.to_s]="1"

    assert_emails 1 do
      post :isa_publish,params.merge(:id=>df)
    end

    assert_response :success

    request_publishing_df.reload
    assert !request_publishing_df.is_published?, "This Datafile should not be published yet, but the publishing request was sent to the gatekeepers"
  end


  test "cannot get isa_publishing_preview when not manageable" do
    login_as(:quentin)
    df=data_file_for_publishing
    assert !df.can_manage?,"The datafile must not be manageable for this test to succeed"
    get :isa_publishing_preview, :id=>df
    assert_redirected_to data_file_path(df)
    assert flash[:error]
  end

  test "can get isa_publishing_preview when manageable but not neccessarily publishable" do
    #define gatekeeper to make asset not publishable
    gatekeeper = Factory(:gatekeeper)
    df=Factory :data_file, :contributor=>users(:datafile_owner), :projects=>gatekeeper.projects
    assert df.can_manage?,"The datafile must be manageable for this test to succeed"
    assert !df.can_publish?,"The datafile must not be publishable for this test to succeed"
    get :isa_publishing_preview, :id=>df
    assert_response :success
    assert_nil flash[:error]
  end

  test "can get isa_publishing_preview when publishable, coz publishable includes manageable" do
    df=data_file_for_publishing
    assert df.can_publish?,"The datafile must be publishable for this test to succeed"
    get :isa_publishing_preview, :id=>df
    assert_response :success
    assert_nil flash[:error]
  end

  test "notification email delivery count and response with complex ownerships" do
    inv,study,assay,df1,df2,df3 = isa_with_complex_sharing
    params={:publish=>{}}
    [inv,study,assay,df1,df2,df3].each do |r|
      params[:publish][r.class.name]||={}
      params[:publish][r.class.name][r.id.to_s]="1"
    end
    assert_emails 2 do
      post :isa_publish,params.merge(:id=>df3)
    end
    assert_response :success

    assert_select "ul#published" do
      assert_select "li",:text=>/Investigation: #{inv.title}/,:count=>1
      assert_select "li",:text=>/Study: #{study.title}/,:count=>0
      assert_select "li",:text=>/Assay: #{assay.title}/,:count=>0
      assert_select "li",:text=>/Data file: #{df1.title}/,:count=>0
      assert_select "li",:text=>/Data file: #{df2.title}/,:count=>1
      assert_select "li",:text=>/Data file: #{df3.title}/,:count=>1
    end
    personB=study.contributor
    personC=df2.contributor
    personA=df3.contributor

    assert_select "ul#notified" do
      assert_select "li",:text=>/Study: #{study.title}/,:count=>1
      assert_select "li",:text=>/Modelling analysis: #{assay.title}/,:count=>1
      assert_select "li",:text=>/Data file: #{df1.title}/,:count=>1

      assert_select "li > a[href=?]",person_path(personB),:text=>/#{personB.name}/,:count=>3
      assert_select "li > a[href=?]",person_path(personC),:text=>/#{personC.name}/,:count=>2
      assert_select "li > a[href=?]",person_path(personA),:text=>/#{personA.name}/,:count=>0
    end
  end
  private

  def data_file_for_publishing(owner=users(:datafile_owner))
    Factory :data_file, :contributor=>owner, :projects=>[projects(:moses_project)]
  end

  def isa_with_complex_sharing
    userA=users(:datafile_owner) #logged in user
    userB=Factory :user
    p=userA.person
    userC=Factory :user
    userD=Factory :user #doesn't manage anything, just can_view

    assay = Factory :assay, :contributor=>userB.person,
                    :study=>Factory(:study,:contributor=>userB.person,
                                    :investigation=>Factory(:investigation, :contributor=>userA.person))
    study=assay.study
    inv=study.investigation

    assay.policy.permissions << Factory(:permission,:policy=>assay.policy,:contributor=>userC.person,:access_type=>Policy::MANAGING)
    study.policy.permissions << Factory(:permission,:policy=>study.policy,:contributor=>userC.person,:access_type=>Policy::MANAGING)
    inv.policy.permissions << Factory(:permission, :policy=>inv.policy,:contributor=>userB.person,:access_type=>Policy::MANAGING)

    df1 = Factory :data_file,:contributor=>userB.person,:projects=>userB.person.projects
    df2 = Factory :data_file,:contributor=>userC.person,:projects=>userC.person.projects
    df3 = Factory :data_file,:contributor=>userA.person,:projects=>[projects(:moses_project)]

    df1.policy.permissions << Factory(:permission,:policy=>df1.policy,:contributor=>userD.person, :access_type=>Policy::VISIBLE)
    df2.policy.permissions << Factory(:permission,:policy=>df2.policy,:contributor=>userD.person, :access_type=>Policy::VISIBLE)
    df2.policy.permissions << Factory(:permission,:policy=>df2.policy,:contributor=>userA.person, :access_type=>Policy::MANAGING)

    disable_authorization_checks do
      assay.relate(df1)
      assay.relate(df2)
      assay.relate(df3)
    end
                                 #some sanity checks that the data structure is as expected
    assert_equal 1, inv.studies.count
    assert_equal 1, inv.studies.first.assays.count

    assert assay.can_manage?(userB)
    assert assay.can_manage?(userC)
    assert !assay.can_manage?(userA)
    assert !assay.can_manage?(userD)

    assert study.can_manage?(userB)
    assert study.can_manage?(userC)
    assert !study.can_manage?(userA)
    assert !study.can_manage?(userD)

    assert inv.can_manage?(userA)
    assert inv.can_manage?(userB)
    assert !inv.can_manage?(userC)
    assert !inv.can_manage?(userD)

    assert df1.can_manage?(userB)
    assert !df1.can_manage?(userC)
    assert !df1.can_manage?(userA)
    assert !df1.can_manage?(userD)

    assert df2.can_manage?(userC)
    assert df2.can_manage?(userA)
    assert !df2.can_manage?(userB)
    assert !df2.can_manage?(userD)

    assert df3.can_manage?(userA)
    assert !df3.can_manage?(userB)
    assert !df3.can_manage?(userC)
    assert !df3.can_manage?(userD)

    assert_equal 3,assay.assets.count

    assert assay.assets.include?(df1.versions.first)
    assert assay.assets.include?(df2.versions.first)
    assert assay.assets.include?(df3.versions.first)

    [inv,study,assay,df1,df2,df3]
  end

  def data_with_isa
    df = data_file_for_publishing
    other_user = users(:quentin)
    assay = Factory :experimental_assay, :contributor=>df.contributor.person, :study=>Factory(:study,:contributor=>df.contributor.person)
    other_persons_data_file = Factory :data_file, :contributor=>other_user, :projects=>other_user.person.projects,:policy=>Factory(:policy, :sharing_scope => Policy::ALL_SYSMO_USERS, :access_type => Policy::VISIBLE)
    assay.relate(df)
    assay.relate(other_persons_data_file)
    assert !other_persons_data_file.can_manage?
    df
  end

end
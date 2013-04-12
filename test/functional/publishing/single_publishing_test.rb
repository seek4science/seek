require 'test_helper'

class SinglePublishingTest < ActionController::TestCase

  tests DataFilesController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end

  test "should be able to do publish when publishable" do
    df=data_file_for_publishing
    assert df.can_publish?,"The data file must be manageable for this test to succeed"

    get :show,:id=>df
    assert_response :success
    assert_select "a", :text => /Publish Data file/

    post :publish,:id=>df
    assert_response :success
    assert_nil flash[:error]
  end

  test "should not be able to do publish when not publishable" do
    df=Factory(:data_file, :policy => Factory(:all_sysmo_viewable_policy))
    assert df.can_view?,"The datafile must be viewable for this test to be meaningful"
    assert !df.can_publish?,"The datafile must not be manageable for this test to succeed"

    get :show,:id=>df
    assert_response :success
    assert_select "a", :text => /Publish Data file/, :count => 0

    post :publish,:id=>df
    assert_redirected_to :root
    assert flash[:error]
  end

  test "get publish redirected" do
    #This is useful because if you logout it redirects back to the current page.
    #If you just published something, that will do a get request to *Controller#isa_publish
    df=data_file_for_publishing
    get :publish, :id => df.id
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
    publishing_df = Factory(:data_file,
                            :contributor => users(:datafile_owner),
                            :assays => [assay])

    assert_not_nil assay,"There should be an assay associated"
    assert df.can_publish?,"The datafile must be publishable for this test to succeed"
    assert request_publishing_df.can_publish?,"The datafile must not be publishable for this test to succeed"
    assert !notifying_df.can_publish?,"The datafile must not be publishable for this test to succeed"

    get :isa_publishing_preview, :item_type=>df.class.name, :item_id => df.id, "#{df.class.name}_#{df.id}_related_items_checked" => "true"
    assert_response :success

    assert_select "li.type_and_title",:text=>/Assay/,:count=>1 do
      assert_select "a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[type='checkbox'][id=?]","publish_Assay_#{assay.id}"
    end

    assert_select "li.type_and_title",:text=>/Data file/,:count=>3 do
      assert_select "a[href=?]",data_file_path(publishing_df),:text=>/#{publishing_df.title}/
      assert_select "a[href=?]",data_file_path(request_publishing_df),:text=>/#{request_publishing_df.title}/
      assert_select "a[href=?]",data_file_path(notifying_df),:text=>/#{notifying_df.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[type='checkbox'][id=?]","publish_DataFile_#{publishing_df.id}"
      assert_select "input[type='checkbox'][id=?]","publish_DataFile_#{request_publishing_df.id}"
      assert_select "input[disabled='disabled'][type='checkbox'][id=?]","publish_DataFile_#{notifying_df.id}"
    end

    assert_select "li.type_and_title",:text=>/Study/,:count=>1 do
      assert_select "a[href=?]",study_path(study),:text=>/#{study.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[type='checkbox'][id=?]","publish_Study_#{study.id}"
    end

    assert_select "li.type_and_title",:text=>/Investigation/,:count=>1 do
      assert_select "a[href=?]",investigation_path(investigation),:text=>/#{investigation.title}/
    end
    assert_select "li.secondary",:text=>/Publish/ do
      assert_select "input[type='checkbox'][id=?]","publish_Investigation_#{investigation.id}"
    end

  end

  test "waiting_approval_list" do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file,:projects=>gatekeeper.projects,:contributor=>User.current_user)
    model = Factory(:model,:projects=>gatekeeper.projects,:contributor=>User.current_user)
    sop = Factory(:sop,:contributor=>User.current_user)
    assert df.gatekeeper_required?,"This datafile must require gatekeeper's approval for the test to succeed"
    assert model.gatekeeper_required?,"This model must require gatekeeper's approval for the test to succeed"
    assert !sop.gatekeeper_required?,"This sop must not require gatekeeper's approval for the test to succeed"

    params = {'DataFile'=>{df.id=>1},'Model'=>{model.id=>1},'Sop'=>{sop.id=>1}}

    get :waiting_approval_list, :publish=>ActiveSupport::JSON.encode(params)
    assert_response :success

    assert_select "a[href=?]", data_file_path(df), :text => /#{df.title}/, :count => 1
    assert_select "a[href=?]", model_path(model), :text => /#{model.title}/, :count => 1
    assert_select "a[href=?]", sop_path(sop), :text => /#{sop.title}/, :count => 0
    assert_select "a[href=?]", person_path(gatekeeper), :text => /#{gatekeeper.name}/, :count => 2
  end

  test "do publish" do
    df=data_file_for_publishing
    assert !df.is_published?,"The data file must not be already published for this test to succeed"
    assert df.can_publish?,"The data file must be publishable for this test to succeed"

    params={:publish=>{}}
    params[:publish][df.class.name]||={}
    params[:publish][df.class.name][df.id.to_s]="1"

    assert_difference("ResourcePublishLog.count", 1) do
      post :publish,params.merge(:id=> df.id)
    end

    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    df.reload
    assert df.is_published?,"The data file should be published after doing single_publish"
  end

  test "sending publishing request when doing publish for asset that need gatekeeper's approval" do
    df=Factory(:data_file, :contributor => User.current_user, :projects => Factory(:gatekeeper).projects)
    assert df.can_publish?,"The data file must be publishable for this test to succeed"
    assert df.gatekeeper_required?,"This datafile must need gatekeeper's approval for the test to succeed'"
    assert  !df.is_waiting_approval?(User.current_user),"The publishing request for this data file must not be sent for this test to succeed"

    params={:publish=>{}}
    params[:publish][df.class.name]||={}
    params[:publish][df.class.name][df.id.to_s]="1"

    assert_difference("ResourcePublishLog.count", 1) do
      assert_emails 1 do
        post :publish,params.merge(:id=> df.id)
      end
    end

    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    df.reload
    assert !df.is_published?,"The data file should not be published after sending publishing request"
    assert df.is_waiting_approval?(User.current_user),"The publishing request for this data file should be sent after requesting"
  end

  test 'do publish together with ISA' do
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

    assert_emails 0 do
      post :publish,params.merge(:id=>df)
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

  test "do publish some" do
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
      post :publish,params.merge(:id=>df)
    end

    assert_response :success

    df.reload

    assert df.is_published?, "Datafile should now be published"
    df.assays.each do |assay|
      assert !assay.is_published?, "The assay was not requested to be published"
      assert assay.study.is_published?, "The study should now be published"
      assert !assay.study.investigation.is_published?, "The investigation was not requested to be published"
    end
    non_owned_assets.each {|a| assert !a.is_published?, "Non manageable assets should not have been published"}

  end

  test 'published' do
    df=data_with_isa
    assay=df.assays.first
    request_publishing_df = Factory(:data_file,
                                    :contributor=>User.current_user,
                                    :projects=>Factory(:gatekeeper).projects,
                                    :assays=>[assay])
    params={:publish => {}}
    params[:publish]["Assay"]||={}
    params[:publish]["Study"]||={}
    params[:publish]["Study"][assay.study.id.to_s]="1"
    params[:publish]["Investigation"]||={}
    assay.assets.collect{|a| a.parent}.each do |asset|
      params[:publish][asset.class.name]||={}
      params[:publish][asset.class.name][asset.id.to_s]="1"
    end

    post :publish,params.merge(:id=>df)
    assert_response :success

    assert_select "ul#published" do
      assert_select "li",:text=>/Investigation: #{assay.study.investigation.title}/,:count=>0
      assert_select "li",:text=>/Study: #{assay.study.title}/,:count=>1
      assert_select "li",:text=>/Assay: #{assay.title}/,:count=>0
      assert_select "li",:text=>/Data file: #{df.title}/,:count=>1
    end

    assert_select "ul#publish_requested" do
      assert_select "li",:text=>/Data file: #{request_publishing_df.title}/,:count=>1
    end

    assert_select "ul#notified", :count => 0
  end

  private

  def data_file_for_publishing(owner=users(:datafile_owner))
    Factory :data_file, :contributor=>owner, :projects=>[projects(:moses_project)]
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
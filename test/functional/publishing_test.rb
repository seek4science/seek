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

  test "get publish redirects to show" do
    #This is useful because if you logout it redirects back to the current page.
    #If you just published something, that will do a get request to *Controller#publish
    get :publish
    assert_response :redirect
  end

  test "get preview_publish" do
    df=data_with_isa
    assay=df.assays.first
    study=assay.study
    investigation=study.investigation
    
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
    assert_select "li.secondary",:text=>/Notify contributor/ do
      assert_select "input[checked='checked'][type='checkbox'][id=?]","publish_DataFile_#{other_df.id}"
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

  test "do publish all" do
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
      assert assay.study.is_published?
      assert !assay.study.investigation.is_published?, "The investigation was not requested to be published"
    end
    non_owned_assets.each {|a| assert !a.is_published?, "Non manageable assets should not have been published"}

  end

  test "cannot get preview_publish when not manageable" do
    login_as(:quentin)
    df=data_file_for_publishing
    assert !df.can_manage?,"The datafile must not be manageable for this test to succeed"
    get :preview_publish, :id=>df
    assert_redirected_to data_file_path(df)
    assert flash[:error]
  end

  test "notification email delivery count and response with complex ownerships" do
    inv,study,assay,df1,df2,df3 = isa_with_complex_sharing
    params={:publish=>{}}
    [inv,study,assay,df1,df2,df3].each do |r|
      params[:publish][r.class.name]||={}
      params[:publish][r.class.name][r.id.to_s]="1"
    end
    assert_emails 2 do
      post :publish,params.merge(:id=>df3)
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

    assert_select "ul#problematic" do
      assert_select "li",1
      assert_select "li",:text=>/No items/,:count=>1
    end
  end

  test 'should not allow to approve/reject publishing for non-gatekeeper' do
    login_as(:quentin)
    df = Factory(:data_file,:projects => people(:quentin_person).projects)
    get :approve_or_reject_publish, :id=>df.id
    assert_redirected_to :root
    assert_not_nil flash[:error]

    get :approve_publish, :id => df.id
    assert_redirected_to :root
    assert_not_nil flash[:error]

    get :reject_publish, :id => df.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test "gracefully handle approve_or_reject for deleted items" do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file,:projects => gatekeeper.projects)
    login_as(df.contributor)
    put :update, :id => df.id, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}

    id = df.id
    disable_authorization_checks do
      df.destroy
      assert_nil(DataFile.find_by_id(df.id))
    end

    logout
    login_as(gatekeeper.user)
    get :approve_or_reject_publish, :id=>0
    assert_redirected_to :root
    assert_not_nil flash[:error]
    assert_equal "This Data file no longer exists, and may have been deleted since the request to publish was made.",flash[:error]
  end

  test 'gatekeeper should approve/reject publishing' do
    as_not_virtualliver do
      gatekeeper = Factory(:gatekeeper)
      df = Factory(:data_file, :projects => gatekeeper.projects)
      login_as(df.contributor)
      put :update, :id => df.id, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}

      logout

      login_as(gatekeeper.user)
      get :approve_or_reject_publish, :id => df.id
      assert_response :success
      assert_nil flash[:error]

      post :reject_publish, :id => df.id
      assert_redirected_to data_file_path(df)
      assert_nil flash[:error]
      df.reload
      assert_not_equal Policy::EVERYONE, df.policy.sharing_scope

      post :approve_publish, :id => df.id
      assert_redirected_to data_file_path(df)
      assert_nil flash[:error]
      df.reload
      assert_equal Policy::EVERYONE, df.policy.sharing_scope
      assert_equal Policy::ACCESSIBLE, df.policy.access_type
    end
  end

  test 'should not allow to approve/reject publishing for gatekeeper from other projects' do
      gatekeeper = Factory(:gatekeeper)
      df = Factory(:data_file)
      login_as(df.contributor)
      put :update, :id => df.id, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}
      logout

      assert (df.projects&gatekeeper.projects).empty?
      login_as(gatekeeper.user)
      get :approve_or_reject_publish, :id=>df.id
      assert_redirected_to :root
      assert_not_nil flash[:error]

      get :approve_publish, :id => df.id
      assert_redirected_to :root
      assert_not_nil flash[:error]

      get :reject_publish, :id => df.id
      assert_redirected_to :root
      assert_not_nil flash[:error]
  end

  test 'log when creating the public item' do
      @controller = SopsController.new()
      sop_params = valid_sop
      sop_params[:projects] = [projects(:three)] #this project has no gatekeeper
      assert_difference ('ResourcePublishLog.count') do
        post :create, :sop => sop_params, :sharing => public_sharing
      end
      publish_log = ResourcePublishLog.find(:last)
      assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
      sop = assigns(:sop)
      assert_equal sop, publish_log.resource
      assert_equal sop.contributor, publish_log.culprit
    end

    test 'log when creating item and request publish it' do
      as_not_virtualliver do
        @controller = SopsController.new()
        assert_difference ('ResourcePublishLog.count') do
          post :create, :sop => valid_sop, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}
        end
        publish_log = ResourcePublishLog.find(:last)
        assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, publish_log.publish_state.to_i
        sop = assigns(:sop)
        assert_equal sop, publish_log.resource
        assert_equal sop.contributor, publish_log.culprit
      end
    end

    test 'dont log when creating the non-public item' do
      @controller = SopsController.new()
      assert_no_difference ('ResourcePublishLog.count') do
        post :create, :sop => valid_sop
      end

      assert_not_equal Policy::EVERYONE, assigns(:sop).policy.sharing_scope
    end

    test 'log when updating an item from non-public to public' do
      @controller = SopsController.new()
      login_as(:owner_of_my_first_sop)

      sop = sops(:sop_with_project_without_gatekeeper)
      assert_not_equal Policy::EVERYONE, sop.policy.sharing_scope
      assert sop.can_publish?

      assert_difference ('ResourcePublishLog.count') do
        put :update, :id => sop.id, :sharing => public_sharing
      end
      publish_log = ResourcePublishLog.find(:last)
      assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
      sop = assigns(:sop)
      assert_equal sop, publish_log.resource
      assert_equal sop.contributor, publish_log.culprit
    end

    test 'log when sending the publish request approval during updating a non-public item' do
      as_not_virtualliver do
        @controller = SopsController.new()
        login_as(:owner_of_my_first_sop)

        sop = sops(:my_first_sop)
        assert_not_equal Policy::EVERYONE, sop.policy.sharing_scope
        assert !sop.can_publish?

        assert_difference ('ResourcePublishLog.count') do
          put :update, :id => sop.id, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}
        end
        publish_log = ResourcePublishLog.find(:last)
        assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, publish_log.publish_state.to_i
        sop = assigns(:sop)
        assert_equal sop, publish_log.resource
        assert_equal sop.contributor, publish_log.culprit
      end
    end

    test 'dont log when updating an item with the not-related public sharing' do
      @controller = SopsController.new()
      login_as(:owner_of_my_first_sop)
      sop = sops(:my_first_sop)
      assert_not_equal Policy::EVERYONE, sop.policy.sharing_scope

      assert_no_difference ('ResourcePublishLog.count') do
        put :update, :id => sop.id, :sharing => {:sharing_scope => Policy::PRIVATE, "access_type_#{Policy::PRIVATE}" => Policy::NO_ACCESS}
      end
    end

    test 'log when un-publishing an item' do
      as_not_virtualliver do
        @controller = SopsController.new()
        login_as(:owner_of_fully_public_policy)

        sop = sops(:sop_with_fully_public_policy)
        assert_equal Policy::EVERYONE, sop.policy.sharing_scope

      #create a published log for the published sop
      ResourcePublishLog.create(:resource => sop, :culprit => User.current_user, :publish_state => ResourcePublishLog::PUBLISHED)

        assert_difference ('ResourcePublishLog.count') do
          put :update, :id => sop.id, :sharing => {:sharing_scope => Policy::PRIVATE, "access_type_#{Policy::PRIVATE}" => Policy::NO_ACCESS}
        end
        publish_log = ResourcePublishLog.find(:last)
        assert_equal ResourcePublishLog::UNPUBLISHED, publish_log.publish_state.to_i
        sop = assigns(:sop)
        assert_equal sop, publish_log.resource
        assert_equal sop.contributor, publish_log.culprit
      end
    end

    test 'log when approving publishing an item' do
      as_not_virtualliver do
        gatekeeper = Factory(:gatekeeper)
        df = Factory(:data_file, :projects => gatekeeper.projects)

        login_as(df.contributor)
        put :update, :id => df.id, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}

        logout

        login_as(gatekeeper.user)
        assert_difference ('ResourcePublishLog.count') do
          put :approve_publish, :id => df.id
        end

        publish_log = ResourcePublishLog.find(:last)
        assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
        df = assigns(:data_file)
        assert_equal df, publish_log.resource
        assert_equal gatekeeper.user, publish_log.culprit
      end
    end

  test 'do not allow to approve_publish if the asset is not in waiting_for_approval state' do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file, :projects => gatekeeper.projects)

    login_as(gatekeeper.user)
    put :approve_publish, :id => df.id

    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'allow to approve_publish if the asset is in waiting_for_approval state' do
    as_not_virtualliver do
      gatekeeper = Factory(:gatekeeper)
      df = Factory(:data_file, :projects => gatekeeper.projects)

      login_as(df.contributor)
      put :update, :id => df.id, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}

    df.reload

      logout

      login_as(gatekeeper.user)
      put :approve_publish, :id => df.id

      assert_nil flash[:error]
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
    other_persons_data_file = Factory :data_file, :contributor=>other_user, :projects=>other_user.person.projects,:policy=>Factory(:policy, :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)
    assay.relate(df)
    assay.relate(other_persons_data_file)
    assert !other_persons_data_file.can_manage?
    df
  end

  def public_sharing
    {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::ACCESSIBLE}
  end

  def valid_sop
    {:title => "Test", :data => fixture_file_upload('files/file_picture.png'), :projects => [projects(:sysmo_project)]}
  end
end


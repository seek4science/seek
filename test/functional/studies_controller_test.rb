require 'test_helper'

class StudiesControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include FunctionalAuthorizationTests

  def setup
    login_as Factory(:admin).user
  end

  def rest_api_test_object
    @object=Factory :study, :policy => Factory(:public_policy)
  end

  test "should get index" do
    Factory :study, :policy => Factory(:public_policy)
    get :index
    assert_response :success
    assert_not_nil assigns(:studies)
    assert !assigns(:studies).empty?
  end

  test "should show aggregated publications linked to assay" do
    assay1 = Factory :assay,:policy => Factory(:public_policy)
    assay2 = Factory :assay,:policy => Factory(:public_policy)

    pub1 = Factory :publication, :title=>"pub 1"
    pub2 = Factory :publication, :title=>"pub 2"
    pub3 = Factory :publication, :title=>"pub 3"
    Factory :relationship, :subject=>assay1, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub1
    Factory :relationship, :subject=>assay1, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub2

    Factory :relationship, :subject=>assay2, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub2
    Factory :relationship, :subject=>assay2, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub3

    study = Factory(:study,:assays=>[assay1,assay2],:policy => Factory(:public_policy))

    get :show,:id=>study.id
    assert_response :success

    assert_select "div.tabbertab" do
      assert_select "h3",:text=>"Publications (3)",:count=>1
    end
  end

  test "should show draggable icon in index" do
    get :index
    assert_response :success
    studies = assigns(:studies)
    first_study = studies.first
    assert_not_nil first_study
    assert_select "a[id*=?]",/drag_Study_#{first_study.id}/
  end
  
  def test_title
    get :index
    assert_select "title",:text=>/The Sysmo SEEK #{I18n.t('study').pluralize}.*/i, :count=>1
  end

  test "should get show" do
    study = Factory(:study, :policy => Factory(:public_policy))
    get :show, :id=>study.id
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test "should get new with investigation predefined even if not member of project" do
    #this scenario arose whilst fixing the test "should get new with investigation predefined"
    #when passing the investigation_id, if that is editable but current_user is not a member,
    #then the investigation should be added to the list
    inv = investigations(:metabolomics_investigation)

    assert inv.can_edit?,"model owner should be able to edit this investigation"
    get :new, :investigation_id=>inv
    assert_response :success

    assert_select "select#study_investigation_id" do
      assert_select "option[selected='selected'][value=?]",inv.id
    end
  end

  test "should get new with investigation predefined" do
    login_as :model_owner
    inv = investigations(:metabolomics_investigation)

    assert inv.can_edit?,"model owner should be able to edit this investigation"
    get :new, :investigation_id=>inv
    assert_response :success

    assert_select "select#study_investigation_id" do
      assert_select "option[selected='selected'][value=?]",inv.id
    end
  end

  test "should not allow linking to an investigation from a project you are not a member of" do
    login_as(:owner_of_my_first_sop)
    inv = investigations(:metabolomics_investigation)
    assert !inv.projects.map(&:people).flatten.include?(people(:person_for_owner_of_my_first_sop)), "this person should not be a member of the investigations project"
    assert !inv.can_edit?(users(:owner_of_my_first_sop))
    get :new, :investigation_id=>inv
    assert_response :success

    assert_select "select#study_investigation_id" do
      assert_select "option[selected='selected'][value=?]",0
    end

    assert_not_nil flash.now[:error]
  end


  test "should get edit" do
    get :edit,:id=>studies(:metabolomics_study)
    assert_response :success
    assert_not_nil assigns(:study)
  end  
  
  test "shouldn't show edit for unauthorized users" do
    s = Factory :study, :policy => Factory(:private_policy)
    login_as(Factory(:user))
    get :edit, :id=>s
    assert_redirected_to study_path(s)
    assert flash[:error]
  end

  test "should update" do
    s=studies(:metabolomics_study)
    assert_not_equal "test",s.title
    put :update,:id=>s.id,:study=>{:title=>"test"}
    s=assigns(:study)
    assert_redirected_to study_path(s)
    assert_equal "test",s.title
  end

  test "should create" do
    assert_difference("Study.count") do
      post :create,:study=>{:title=>"test",:investigation_id=>investigations(:metabolomics_investigation).id}, :sharing=>valid_sharing

    end
    s=assigns(:study)
    assert_redirected_to study_path(s)
  end  

  test "should update sharing permissions" do
    login_as(Factory(:user))
    s = Factory :study,:contributor => User.current_user.person, :policy => Factory(:public_policy)
    assert s.can_manage?(User.current_user),"This user should be able to manage this study"
    
    assert_equal Policy::MANAGING,s.policy.sharing_scope
    assert_equal Policy::EVERYONE,s.policy.access_type

    put :update,:id=>s,:study=>{},:sharing=>{"access_type_#{Policy::NO_ACCESS}"=>Policy::NO_ACCESS,:sharing_scope=>Policy::PRIVATE}
    s=assigns(:study)
    assert_response :redirect
    s.reload
    assert_equal Policy::PRIVATE,s.policy.sharing_scope
    assert_equal Policy::NO_ACCESS,s.policy.access_type
  end

  test "should not update sharing permissions to remove your own manage rights" do
    login_as(Factory(:user))
    s = Factory :study,:contributor => Factory(:person), :policy => Factory(:public_policy)
    assert s.can_manage?(User.current_user),"This user should be able to manage this study"

    assert_equal Policy::MANAGING, s.policy.sharing_scope
    assert_equal Policy::EVERYONE, s.policy.access_type

    put :update,:id=>s,:study=>{},:sharing=>{"access_type_#{Policy::NO_ACCESS}"=>Policy::NO_ACCESS,:sharing_scope=>Policy::PRIVATE}
    s=assigns(:study)
    assert_response :success
    s.reload
    assert_equal Policy::MANAGING, s.policy.sharing_scope
    assert_equal Policy::EVERYONE, s.policy.access_type
  end

  test "should not create with assay already related to study" do
    assert_no_difference("Study.count") do
      post :create,:study=>{:title=>"test",:investigation=>investigations(:metabolomics_investigation),:assay_ids=>[assays(:metabolomics_assay3).id]}
    end
    s=assigns(:study)
    assert flash[:error]
    assert_response :redirect        
  end

  test "should not update with assay already related to study" do
    s=studies(:metabolomics_study)
    put :update,:id=>s.id,:study=>{:title=>"test",:assay_ids=>[assays(:metabolomics_assay3).id]}
    s=assigns(:study)
    assert flash[:error]
    assert_response :redirect
  end

  test "should can update with assay already related to this study" do
    s=studies(:metabolomics_study)
    put :update,:id=>s.id,:study=>{:title=>"new title",:assay_ids=>[assays(:metabolomics_assay).id]}
    s=assigns(:study)
    assert !flash[:error]
    assert_redirected_to study_path(s)
    assert_equal "new title",s.title
    assert s.assays.include?(assays(:metabolomics_assay))
  end

  test "no edit button shown for people who can't edit the study" do
    login_as Factory(:user)
    study = Factory :study, :policy => Factory(:private_policy)
    get :show, :id=>study
    assert_select "a",:text=>/Edit #{I18n.t('study')}/i,:count=>0
  end

  test "edit button in show for person in project" do
    get :show, :id=>studies(:metabolomics_study)
    assert_select "a",:text=>/Edit #{I18n.t('study')}/i,:count=>1
  end


  test "unauthorized user can't update" do
    s=Factory :study, :policy => Factory(:private_policy)
    login_as(Factory(:user))
    Factory :permission, :contributor => User.current_user, :policy=> s.policy, :access_type => Policy::VISIBLE

    put :update, :id=>s.id,:study=>{:title=>"test"}

    assert_redirected_to study_path(s)
    assert flash[:error]
  end

  test "authorized user can delete if no assays" do
    study = Factory(:study, :contributor => Factory(:person))
    login_as study.contributor.user
    assert_difference('Study.count',-1) do
      delete :destroy, :id => study.id
    end    
    assert !flash[:error]
    assert_redirected_to studies_path
  end

  test "study non project member cannot delete even if no assays" do
    login_as(:aaron)
    study = studies(:study_with_no_assays)
    assert_no_difference('Study.count') do
      delete :destroy, :id => study.id
    end
    assert flash[:error]
    assert_redirected_to study
  end
  
  test "study project member cannot delete if assays associated" do
    study = studies(:metabolomics_study)
    assert_no_difference('Study.count') do
      delete :destroy, :id => study.id
    end
    assert flash[:error]
    assert_redirected_to study
  end
  
  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> studies(:study_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

  def test_assay_tab_doesnt_show_private_sops_or_datafiles
    login_as(:model_owner)
    study=studies(:study_with_assay_with_public_private_sops_and_datafile)
    get :show,:id=>study
    assert_response :success

    assert_select "div.tabbertab" do
      assert_select "h3",:text=>"#{I18n.t('assays.assay').pluralize} (1)",:count=>1
      assert_select "h3",:text=>"#{I18n.t('sop').pluralize} (1+1)",:count=>1
      assert_select "h3",:text=>"#{I18n.t('data_file').pluralize} (1+1)",:count=>1
    end

    assert_select "div.list_item" do
      #the Assay resource_list_item
      assert_select "p.list_item_attribute a[title=?]",sops(:sop_with_fully_public_policy).title,:count=>1
      assert_select "p.list_item_attribute a[href=?]",sop_path(sops(:sop_with_fully_public_policy)),:count=>1
      assert_select "p.list_item_attribute a[title=?]",sops(:sop_with_private_policy_and_custom_sharing).title,:count=>0
      assert_select "p.list_item_attribute a[href=?]",sop_path(sops(:sop_with_private_policy_and_custom_sharing)),:count=>0

      assert_select "p.list_item_attribute a[title=?]",data_files(:downloadable_data_file).title,:count=>1
      assert_select "p.list_item_attribute a[href=?]",data_file_path(data_files(:downloadable_data_file)),:count=>1
      assert_select "p.list_item_attribute a[title=?]",data_files(:private_data_file).title,:count=>0
      assert_select "p.list_item_attribute a[href=?]",data_file_path(data_files(:private_data_file)),:count=>0

      #the Sops and DataFiles resource_list_item
      assert_select "div.list_item_title a[href=?]",sop_path(sops(:sop_with_fully_public_policy)),:text=>"SOP with fully public policy",:count=>1
      assert_select "div.list_item_actions a[href=?]",sop_path(sops(:sop_with_fully_public_policy)),:count=>1
      assert_select "div.list_item_title a[href=?]",sop_path(sops(:sop_with_private_policy_and_custom_sharing)),:count=>0
      assert_select "div.list_item_actions a[href=?]",sop_path(sops(:sop_with_private_policy_and_custom_sharing)),:count=>0

      assert_select "div.list_item_title a[href=?]",data_file_path(data_files(:downloadable_data_file)),:text=>"Download Only",:count=>1
      assert_select "div.list_item_actions a[href=?]",data_file_path(data_files(:downloadable_data_file)),:count=>1
      assert_select "div.list_item_title a[href=?]",data_file_path(data_files(:private_data_file)),:count=>0
      assert_select "div.list_item_actions a[href=?]",data_file_path(data_files(:private_data_file)),:count=>0
    end
  end
  def test_assay_tab_doesnt_show_private_sops_or_datafiles_with_lazy_load
    login_as(:model_owner)
    study=studies(:study_with_assay_with_public_private_sops_and_datafile)
    with_config_value :tabs_lazy_load_enabled, true do
      get :show, :id => study
      assert_response :success
      assert_select "div.tabbertab" do
        assert_select "h3",:text=>"#{I18n.t('assays.assay').pluralize} (1)",:count=>1
        assert_select "h3",:text=>"#{I18n.t('sop').pluralize} (2)",:count=>1
        assert_select "h3",:text=>"#{I18n.t('data_file').pluralize} (2)",:count=>1
      end
      get :resource_in_tab, {:resource_ids => study.assays.map(&:id).join(","), :resource_type => "Assay", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
      assert_select "div.list_item" do
        #the Assay resource_list_item
        assert_select "p.list_item_attribute a[title=?]", sops(:sop_with_fully_public_policy).title, :count => 1
        assert_select "p.list_item_attribute a[href=?]", sop_path(sops(:sop_with_fully_public_policy)), :count => 1
        assert_select "p.list_item_attribute a[title=?]", sops(:sop_with_private_policy_and_custom_sharing).title, :count => 0
        assert_select "p.list_item_attribute a[href=?]", sop_path(sops(:sop_with_private_policy_and_custom_sharing)), :count => 0

        assert_select "p.list_item_attribute a[title=?]", data_files(:downloadable_data_file).title, :count => 1
        assert_select "p.list_item_attribute a[href=?]", data_file_path(data_files(:downloadable_data_file)), :count => 1
        assert_select "p.list_item_attribute a[title=?]", data_files(:private_data_file).title, :count => 0
        assert_select "p.list_item_attribute a[href=?]", data_file_path(data_files(:private_data_file)), :count => 0
      end

      get :resource_in_tab, {:resource_ids => study.related_sops.map(&:id).join(","), :resource_type => "Sop", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}

      assert_select "div.list_item" do
        # Sops resource_list_item
        assert_select "div.list_item_title a[href=?]", sop_path(sops(:sop_with_fully_public_policy)), :text => "SOP with fully public policy", :count => 1
        assert_select "div.list_item_actions a[href=?]", sop_path(sops(:sop_with_fully_public_policy)), :count => 1
        assert_select "div.list_item_title a[href=?]", sop_path(sops(:sop_with_private_policy_and_custom_sharing)), :count => 0
        assert_select "div.list_item_actions a[href=?]", sop_path(sops(:sop_with_private_policy_and_custom_sharing)), :count => 0
      end
      get :resource_in_tab, {:resource_ids => study.related_data_files.map(&:id).join(","), :resource_type => "DataFile", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}

      assert_select "div.list_item" do
        #DataFiles resource_list_item
        assert_select "div.list_item_title a[href=?]", data_file_path(data_files(:downloadable_data_file)), :text => "Download Only", :count => 1
        assert_select "div.list_item_actions a[href=?]", data_file_path(data_files(:downloadable_data_file)), :count => 1
        assert_select "div.list_item_title a[href=?]", data_file_path(data_files(:private_data_file)), :count => 0
        assert_select "div.list_item_actions a[href=?]", data_file_path(data_files(:private_data_file)), :count => 0
      end

    end
  end
  def test_should_show_investigation_tab
    s=studies(:metabolomics_study)
    get :show,:id=>s
    assert_response :success
    assert_select "div.tabbertab" do
      assert_select "h3",:text=>"#{I18n.t('investigation').pluralize} (1)",:count=>1
    end
  end
  
  test "filtering by investigation" do
    inv=investigations(:metabolomics_investigation)
    get :index, :filter => {:investigation => inv.id}
    assert_response :success
  end

  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
  end

  test "filter by person using nested routes" do
    assert_routing "people/2/studies",{controller:"studies",action:"index",person_id:"2"}
    study = Factory(:study,:policy=>Factory(:public_policy))
    study2 = Factory(:study,:policy=>Factory(:public_policy))
    person = study.contributor.person
    refute_equal study.contributor,study2.contributor
    assert person.is_a?(Person)
    get :index,person_id:person.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "p > a[href=?]",study_path(study),:text=>study.title
      assert_select "p > a[href=?]",study_path(study2),:text=>study2.title,:count=>0
    end
  end

  test 'edit study with selected projects scope policy' do
    proj = User.current_user.person.projects.first
    study = Factory(:study, :contributor => User.current_user.person,
                    :investigation => Factory(:investigation, :project_ids => [proj.id]),
                    :policy => Factory(:policy,
                                       :sharing_scope => Policy::ALL_SYSMO_USERS,
                                       :access_type => Policy::NO_ACCESS,
                                       :permissions => [Factory(:permission, :contributor => proj, :access_type => Policy::EDITING)]))
    get :edit, :id => study.id
  end

  test 'should show the contributor avatar' do
    study = Factory(:study, :policy => Factory(:public_policy))
    get :show, :id => study
    assert_response :success
    assert_select ".author_avatar" do
      assert_select "a[href=?]",person_path(study.contributing_user.person) do
        assert_select "img"
      end
    end
  end

  test 'object based on existing study' do
    study = Factory :study,:title=>"the study",:policy=>Factory(:public_policy),
                    :investigation => Factory(:investigation, :policy => Factory(:public_policy))
    get :new_object_based_on_existing_one,:id=>study.id
    assert_response :success
    assert_select "textarea#study_title",:text=>"the study"
    assert_select "select#study_investigation_id option[selected][value=?]",study.investigation.id,:count=>1
  end

  test 'object based on existing one when unauthorized to view' do
    study = Factory :study,:title=>"the private study",:policy=>Factory(:private_policy)
    refute study.can_view?
    get :new_object_based_on_existing_one,:id=>study.id
    assert_response :forbidden
  end

  test "logged out user can't see new" do
    logout
    get :new
    assert_redirected_to studies_path
  end

  test "new object based on existing one when can view but not logged in" do
    study = Factory(:study,:policy=>Factory(:public_policy))
    logout
    assert study.can_view?
    get :new_object_based_on_existing_one, :id=>study.id
    assert_redirected_to study
    refute_nil flash[:error]
  end

  test 'object based on existing one when unauthorized to edit investigation' do
    inv = Factory(:investigation,:policy=>Factory(:private_policy),:contributor=>Factory(:person))

    study = Factory :study,:title=>"the private study",:policy=>Factory(:public_policy),:investigation=>inv
    assert study.can_view?
    refute study.investigation.can_edit?
    get :new_object_based_on_existing_one,:id=>study.id
    assert_response :success
    assert_select "textarea#study_title",:text=>"the private study"
    assert_select "select#study_investigation_id option[selected][value=?]",study.investigation.id,:count=>0
    refute_nil flash.now[:notice]
  end

  test "studies filtered by assay through nested routing" do
    assert_routing "assays/22/studies",{controller:"studies",action:"index",assay_id:"22"}
    contributor = Factory(:person)
    assay1 = Factory :assay,contributor:contributor,study:Factory(:study,:contributor=>contributor)
    assay2 = Factory :assay,contributor:contributor,study:Factory(:study,:contributor=>contributor)
    login_as contributor
    assert assay1.study.can_view?
    assert assay2.study.can_view?
    get :index,assay_id:assay1.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "p > a[href=?]",study_path(assay1.study),:text=>assay1.study.title
      assert_select "p > a[href=?]",study_path(assay2.study),:text=>assay2.study.title,:count=>0
    end
  end


end

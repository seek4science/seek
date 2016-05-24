require 'test_helper'

class InvestigationsControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include FunctionalAuthorizationTests
  
  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object= Factory(:investigation, :policy => Factory(:public_policy))
  end

  def test_title
    get :index
    assert_select "title",:text=>/The Sysmo SEEK #{I18n.t('investigation').pluralize}.*/i, :count=>1
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:investigations)
  end

  test "should respond to ro for research object" do
    inv = Factory :investigation,:contributor=>User.current_user.person
    get :show,:id=>inv, :format=>"ro"
    assert_response :success
    assert_equal "attachment; filename=\"investigation-#{inv.id}.ro.zip\"",@response.header['Content-Disposition']
    assert_equal "application/vnd.wf4ever.robundle+zip",@response.header['Content-Type']
    assert @response.header['Content-Length'].to_i>10
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

    investigation = Factory(:investigation,:policy => Factory(:public_policy))
    study = Factory(:study,:policy => Factory(:public_policy),
                    :assays=>[assay1,assay2],
                    :investigation => investigation)

    get :show,:id=>study.investigation.id
    assert_response :success

    assert_select "ul.nav-pills" do
      assert_select "a",:text=>"Publications (3)",:count=>1
    end
  end

  test "should show draggable icon in index" do
    get :index
    assert_response :success
    investigations = assigns(:investigations)
    first_investigations = investigations.first
    assert_not_nil first_investigations
    assert_select "a[data-favourite-url=?]", h(add_favourites_path(:resource_id =>first_investigations.id,
                                                                   :resource_type => first_investigations.class.name))
  end

  test "should show item" do
    get :show, :id=>investigations(:metabolomics_investigation)
    assert_response :success
    assert_not_nil assigns(:investigation)
  end

  test "should show new" do
    get :new
    assert_response :success
    assert assigns(:investigation)
  end

  test "logged out user can't see new" do
    logout
    get :new
    assert_redirected_to investigations_path
  end

  test "should show edit" do
    get :edit, :id=>investigations(:metabolomics_investigation)
    assert_response :success
    assert assigns(:investigation)
  end
  
  test "shouldn't show edit for unauthorized user" do
    i = Factory(:investigation, :policy => Factory(:private_policy))
    login_as(Factory(:user))
    get :edit, :id=>i
    assert_redirected_to investigation_path(i)
    assert flash[:error]
  end

  test "should update" do
    i=investigations(:metabolomics_investigation)
    put :update, :id=>i.id,:investigation=>{:title=>"test"}
    
    assert_redirected_to investigation_path(i)
    assert assigns(:investigation)
    assert_equal "test",assigns(:investigation).title
  end

  test "should create" do
    login_as(Factory :user)
    assert_difference("Investigation.count") do
      put :create, :investigation=> Factory.attributes_for(:investigation, :project_ids => [User.current_user.person.projects.first.id]), :sharing => valid_sharing
    end
    assert assigns(:investigation)
    assert !assigns(:investigation).new_record?
  end

  test "should fall back to form when no title validation fails" do
    login_as(Factory :user)

    assert_no_difference("Investigation.count") do
      put :create, :investigation=> {:project_ids => [User.current_user.person.projects.first.id]}
    end
    assert_template :new
    
    assert assigns(:investigation)
    assert !assigns(:investigation).valid?
    assert !assigns(:investigation).errors.empty?

  end

  test "should fall back to form when no projects validation fails" do
    login_as(Factory :user)

    assert_no_difference("Investigation.count") do
      put :create, :investigation=> {:title=>"investigation with no projects"}
    end
    assert_template :new

    assert assigns(:investigation)
    assert !assigns(:investigation).valid?
    assert !assigns(:investigation).errors.empty?

  end

  test "no edit button in show for unauthorized user" do
    login_as(Factory(:user))
    get :show, :id=>Factory(:investigation, :policy => Factory(:private_policy))
    assert_select "a",:text=>/Edit #{I18n.t('investigation')}/i,:count=>0
  end

  test "edit button in show for authorized user" do
    get :show, :id=>investigations(:metabolomics_investigation)
    assert_select "a[href=?]",edit_investigation_path(investigations(:metabolomics_investigation)),:text=>/Edit #{I18n.t('investigation')}/i,:count=>1
  end

  test "no add study button for person that can edit" do
    login_as(:owner_of_my_first_sop)
    inv = investigations(:metabolomics_investigation)
    assert !inv.can_edit?,"Aaron should not be able to edit this investigation"
    get :show, :id=>inv
    assert_select "a",:text=>/Add a #{I18n.t('study')}/i,:count=>0
  end

  test "add study button for person that can edit" do
    inv = investigations(:metabolomics_investigation)
    get :show, :id=>inv
    assert_select "a[href=?]",new_study_path(:investigation_id=>inv),:text=>/Add a #{I18n.t('study')}/i,:count=>1
  end


  test "unauthorized user can't edit investigation" do
    i=Factory(:investigation, :policy => Factory(:private_policy))
    login_as(Factory(:user))
    get :edit, :id=>i
    assert_redirected_to investigation_path(i)
    assert flash[:error]
  end

  test "unauthorized users can't update investigation" do
    i=Factory(:investigation, :policy => Factory(:private_policy))
    login_as(Factory(:user))
    put :update, :id=>i.id,:investigation=>{:title=>"test"}

    assert_redirected_to investigation_path(i)
  end

  test "should destroy investigation" do
    i = Factory(:investigation, :contributor => User.current_user)
    assert_difference("Investigation.count",-1) do
      delete :destroy, :id => i.id
    end
    assert !flash[:error]
    assert_redirected_to investigations_path    
  end

  test "unauthorized user should not destroy investigation" do
    i = Factory(:investigation, :policy => Factory(:private_policy))
    login_as(Factory(:user))
    assert_no_difference("Investigation.count") do
      delete :destroy, :id => i.id
    end
    assert flash[:error]
    assert_redirected_to i
  end

  test "should not destroy investigation with a study" do
    investigation = investigations(:metabolomics_investigation)
    assert_no_difference("Investigation.count") do
      delete :destroy, :id => investigation.id
    end
    assert flash[:error]
    assert_redirected_to investigation
  end

  test "option to delete investigation without study" do    
    get :show,:id=>Factory(:investigation, :contributor => User.current_user).id
    assert_select "a",:text=>/Delete #{I18n.t('investigation')}/i,:count=>1
  end

  test "no option to delete investigation with study" do
    get :show,:id=>investigations(:metabolomics_investigation).id
    assert_select "a",:text=>/Delete #{I18n.t('investigation')}/i,:count=>0
  end

  test "no option to delete investigation when unauthorized" do
    i = Factory :investigation, :policy => Factory(:private_policy)
    login_as Factory(:user)
    get :show,:id=>i.id
    assert_select "a",:text=>/Delete #{I18n.t('investigation')}/i,:count=>0
  end

  test "should_add_nofollow_to_links_in_show_page" do
    get :show, :id=> investigations(:investigation_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

  test "object based on existing one" do
    inv = Factory :investigation,:title=>"the inv",:policy=>Factory(:public_policy)
    get :new_object_based_on_existing_one,:id=>inv.id
    assert_response :success
    assert_select "#investigation_title[value=?]", "the inv"
  end

  test "object based on existing one when unauthorised" do
    inv = Factory :investigation,:title=>"the inv",:policy=>Factory(:private_policy),:contributor=>Factory(:person)
    refute inv.can_view?
    get :new_object_based_on_existing_one,:id=>inv.id
    assert_response :forbidden
  end

  test "new object based on existing one when can view but not logged in" do
    inv = Factory(:investigation,:policy=>Factory(:public_policy))
    logout
    assert inv.can_view?
    get :new_object_based_on_existing_one, :id=>inv.id
    assert_redirected_to inv
    refute_nil flash[:error]
  end

  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
  end

  test 'should show the contributor avatar' do
    investigation = Factory(:investigation, :policy => Factory(:public_policy))
    get :show, :id => investigation
    assert_response :success
    assert_select ".author_avatar" do
      assert_select "a[href=?]",person_path(investigation.contributing_user.person) do
        assert_select "img"
      end
    end
  end

  test 'should add creators' do
    investigation = Factory(:investigation, :policy => Factory(:public_policy))
    creator = Factory(:person)
    assert investigation.creators.empty?

    put :update, :id=>investigation.id, :creators=>[[creator.name,creator.id]].to_json
    assert_redirected_to investigation_path(investigation)

    assert investigation.creators.include?(creator)
  end

  test 'should have creators association box' do
    investigation = Factory(:investigation, :policy => Factory(:public_policy))

    get :edit, :id=> investigation.id
    assert_response :success
    assert_select "p#creators_list"
    assert_select "input[type='text'][name='creator-typeahead']"
    assert_select "input[type='hidden'][name='creators']"
    assert_select "input[type='text'][name='investigation[other_creators]']"

  end

  test 'should show creators' do
    investigation = Factory(:investigation, :policy => Factory(:public_policy))
    creator = Factory(:person)
    investigation.creators = [creator]
    investigation.save
    investigation.reload
    assert investigation.creators.include?(creator)

    get :show, :id=> investigation.id
    assert_response :success
    assert_select "span.author_avatar a[href=?]", "/people/#{creator.id}"
  end

  test 'should show other creators' do
    investigation = Factory(:investigation, :policy => Factory(:public_policy))
    other_creators = 'other creators'
    investigation.other_creators = other_creators
    investigation.save
    investigation.reload

    get :show, :id=> investigation.id
    assert_response :success
    assert_select "div.panel-body div", :text => other_creators
  end

  test "programme investigations through nested routing" do
    assert_routing 'programmes/2/investigations', { controller: 'investigations', action: 'index', programme_id: '2' }
    programme = Factory(:programme)
    investigation = Factory(:investigation, projects: programme.projects, policy: Factory(:public_policy))
    investigation2 = Factory(:investigation, policy: Factory(:public_policy))

    get :index, programme_id: programme.id

    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]", investigation_path(investigation), text: investigation.title
      assert_select "a[href=?]", investigation_path(investigation2), text: investigation2.title, count: 0
    end
  end
end

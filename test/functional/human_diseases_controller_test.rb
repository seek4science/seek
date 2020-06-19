require 'test_helper'

class HumanDiseasesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  # include RestTestCases

  def setup
    login_as(:aaron)
    @old_enabled_status = Seek::Config.human_diseases_enabled
    Seek::Config.human_diseases_enabled = true
  end

  def teardown
    Seek::Config.human_diseases_enabled = @old_enabled_status
  end

  def rest_api_test_object
    @object = Factory(:human_disease, bioportal_concept: Factory(:human_disease_bioportal_concept))
  end

  test 'new human disease route' do
    assert_routing '/human_diseases/new', controller: 'human_diseases', action: 'new'
    assert_equal '/human_diseases/new', new_human_disease_path.to_s
  end

  test 'admin can get edit' do
    login_as(:quentin)
    get :edit, params: { id: human_diseases(:melanoma) }
    assert_response :success
    assert_nil flash[:error]
  end

  test 'non admin cannot get edit' do
    login_as(:aaron)
    get :edit, params: { id: human_diseases(:melanoma) }
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test 'admin can update' do
    login_as(:quentin)
    y = human_diseases(:melanoma)
    put :update, params: { id: y.id, human_disease: { title: 'fffff' } }
    assert_redirected_to human_disease_path(y)
    assert_nil flash[:error]
    y = HumanDisease.find(y.id)
    assert_equal 'fffff', y.title
  end

  test 'non admin cannot update' do
    login_as(:aaron)
    y = human_diseases(:melanoma)
    put :update, params: { id: y.id, human_disease: { title: 'fffff' } }
    assert_redirected_to root_path
    assert_not_nil flash[:error]
    y = HumanDisease.find(y.id)
    assert_equal 'Melanoma', y.title
  end

  test 'admin can get new' do
    login_as(:quentin)
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1', /add a new human disease/i
  end

  test 'project administrator can get new' do
    login_as(Factory(:project_administrator))
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1', /add a new human disease/i
  end

  test 'programme administrator can get new' do
    pa = Factory(:programme_administrator_not_in_project)
    login_as(pa)

    # check not already in a project
    assert_empty pa.projects
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1', /add a new human disease/i
  end

  test 'non admin cannot get new' do
    login_as(:aaron)
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test 'admin has create human disease menu option' do
    login_as(Factory(:admin))
    get :show, params: { id: Factory(:human_disease) }
    assert_response :success
    assert_select 'li#create-menu' do
      assert_select 'ul.dropdown-menu' do
        assert_select 'li a[href=?]', new_human_disease_path, text: 'Human Disease'
      end
    end
  end

  test 'project administrator has create human disease menu option' do
    login_as(Factory(:project_administrator))
    get :show, params: { id: Factory(:human_disease) }
    assert_response :success
    assert_select 'li#create-menu' do
      assert_select 'ul.dropdown-menu' do
        assert_select 'li a[href=?]', new_human_disease_path, text: 'Human Disease'
      end
    end
  end

  test 'non admin doesn not have create human disease menu option' do
    login_as(Factory(:user))
    get :show, params: { id: Factory(:human_disease) }
    assert_response :success
    assert_select 'li#create-menu' do
      assert_select 'ul.dropdown-menu' do
        assert_select 'li a[href=?]', new_human_disease_path, text: 'Human Disease', count: 0
      end
    end
  end

  test 'admin can create new human disease' do
    login_as(:quentin)
    assert_difference('HumanDisease.count') do
      post :create, params: { human_disease: { title: 'An human disease' } }
    end
    assert_not_nil assigns(:human_disease)
    assert_redirected_to human_disease_path(assigns(:human_disease))
  end

  test 'create human disease with concept uri' do
    login_as(:quentin)
    assert_difference('HumanDisease.count') do
      post :create, params: { human_disease: { title: 'germ cell cancer', concept_uri: 'http://purl.obolibrary.org/obo/DOID_2994' } }
    end
    assert_not_nil assigns(:human_disease)

    # uri is converted the taxonomy form
    assert_equal 'http://purl.obolibrary.org/obo/DOID_2994', assigns(:human_disease).concept_uri
  end

  # should convert to the purl version
  test 'create human disease with doid id number' do
    login_as(:quentin)
    assert_difference('HumanDisease.count') do
      post :create, params: { human_disease: { title: 'malignant glioma', concept_uri:'3070' } }
    end
    assert_not_nil assigns(:human_disease)
    assert_equal 'http://purl.bioontology.org/obo/DOID_3070', assigns(:human_disease).concept_uri
  end

  # should convert to the purl version
  test 'update human disease with doid id number' do
    login_as(:quentin)
    disease = Factory(:human_disease)
    patch :update, params: { id: disease.id, human_disease: { concept_uri:'305' } }
    assert_not_nil assigns(:human_disease)
    assert_equal 'http://purl.bioontology.org/obo/DOID_305', assigns(:human_disease).concept_uri
  end

  test 'project administrator can create new human disease' do
    login_as(Factory(:project_administrator))
    assert_difference('HumanDisease.count') do
      post :create, params: { human_disease: { title: 'An human disease' } }
    end
    assert_not_nil assigns(:human_disease)
    assert_redirected_to human_disease_path(assigns(:human_disease))
  end

  test 'programme administrator can create new human disease' do
    login_as(Factory(:programme_administrator_not_in_project))
    assert_difference('HumanDisease.count') do
      post :create, params: { human_disease: { title: 'An human disease' } }
    end
    assert_not_nil assigns(:human_disease)
    assert_redirected_to human_disease_path(assigns(:human_disease))
  end

  test 'non admin cannot create new human disease' do
    login_as(:aaron)
    assert_no_difference('HumanDisease.count') do
      post :create, params: { human_disease: { title: 'An human disease' } }
    end
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test 'delete button disabled for associated human diseases' do
    login_as(:quentin)
    y = human_diseases(:melanoma)
    get :show, params: { id: y }
    assert_response :success
    assert_select 'span.disabled_icon img', count: 1
    assert_select 'span.disabled_icon a', count: 0
  end

  test 'admin sees edit and create buttons' do
    login_as(:quentin)
    y = human_diseases(:sarcoma)
    get :show, params: { id: y }
    assert_response :success
    assert_select '#content a[href=?]', edit_human_disease_path(y), count: 1
    assert_select '#content a', text: /Edit Human Disease/, count: 1

    assert_select '#content a[href=?]', new_human_disease_path, count: 1
    assert_select '#content a', text: /Add Human Disease/, count: 1

    assert_select '#content a', text: /Delete Human Disease/, count: 1
  end

  test 'project administrator sees create buttons' do
    login_as(Factory(:project_administrator))
    y = human_diseases(:sarcoma)
    get :show, params: { id: y }
    assert_response :success

    assert_select '#content a[href=?]', new_human_disease_path, count: 1
    assert_select '#content a', text: /Add Human Disease/, count: 1
  end

  test 'non admin does not see edit, create and delete buttons' do
    login_as(:aaron)
    y = human_diseases(:sarcoma)
    get :show, params: { id: y }
    assert_response :success
    assert_select '#content a[href=?]', edit_human_disease_path(y), count: 0
    assert_select '#content a', text: /Edit Human Disease/, count: 0

    assert_select '#content a[href=?]', new_human_disease_path, count: 0
    assert_select '#content a', text: /Add Human Disease/, count: 0

    assert_select '#content a', text: /Delete Human Disease/, count: 0
  end

  test 'delete as admin' do
    login_as(:quentin)
    d = human_diseases(:sarcoma)
    assert_difference('HumanDisease.count', -1) do
      delete :destroy, params: { id: d }
    end
    assert_redirected_to human_diseases_path
  end

  test 'delete as project administrator' do
    login_as(Factory(:project_administrator))
    d = human_diseases(:sarcoma)
    assert_difference('HumanDisease.count', -1) do
      delete :destroy, params: { id: d }
    end
    assert_redirected_to human_diseases_path
  end

  test 'cannot delete as non-admin' do
    login_as(:aaron)
    d = human_diseases(:sarcoma)
    assert_no_difference('HumanDisease.count') do
      delete :destroy, params: { id: d }
    end
    refute_nil flash[:error]
  end

  test 'visualise available when logged out' do
    logout
    d = Factory(:human_disease, bioportal_concept: Factory(:human_disease_bioportal_concept))
    get :visualise, params: { id: d }
    assert_response :success
  end

  test 'cannot delete associated human disease' do
    login_as(:quentin)
    d = human_diseases(:melanoma)
    assert_no_difference('HumanDisease.count') do
      delete :destroy, params: { id: d }
    end
  end

  test 'create multiple human diseases with blank concept uri' do
    login_as(Factory(:admin))
    assert_difference('HumanDisease.count') do
      post :create, params: { human_disease: { title: 'An human disease', concept_uri:'' } }
    end
    assert_not_nil assigns(:human_disease)
    assert_nil assigns(:human_disease).concept_uri

    assert_difference('HumanDisease.count') do
      post :create, params: { human_disease: { title: 'An human disease 2', concept_uri:'' } }
    end

    refute_nil assigns(:human_disease)
    assert_nil assigns(:human_disease).concept_uri
  end

end

require 'test_helper'

class OrganismsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases

  include RdfTestCases

  def setup
    login_as(:aaron)
  end

  def rest_api_test_object
    @object = Factory(:organism, bioportal_concept: Factory(:bioportal_concept))
  end

  test 'new organism route' do
    assert_routing '/organisms/new', controller: 'organisms', action: 'new'
    assert_equal '/organisms/new', new_organism_path.to_s
  end

  test 'admin can get edit' do
    login_as(:quentin)
    get :edit, params: { id: organisms(:yeast) }
    assert_response :success
    assert_nil flash[:error]
  end

  test 'non admin cannot get edit' do
    login_as(:aaron)
    get :edit, params: { id: organisms(:yeast) }
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test 'admin can update' do
    login_as(:quentin)
    y = organisms(:yeast)
    put :update, params: { id: y.id, organism: { title: 'fffff' } }
    assert_redirected_to organism_path(y)
    assert_nil flash[:error]
    y = Organism.find(y.id)
    assert_equal 'fffff', y.title
  end

  test 'non admin cannot update' do
    login_as(:aaron)
    y = organisms(:yeast)
    put :update, params: { id: y.id, organism: { title: 'fffff' } }
    assert_redirected_to root_path
    assert_not_nil flash[:error]
    y = Organism.find(y.id)
    assert_equal 'yeast', y.title
  end

  test 'admin can get new' do
    login_as(:quentin)
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1', /add a new organism/i
  end

  test 'project administrator can get new' do
    login_as(Factory(:project_administrator))
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1', /add a new organism/i
  end

  test 'programme administrator can get new' do
    pa = Factory(:programme_administrator_not_in_project)
    login_as(pa)

    # check not already in a project
    assert_empty pa.projects
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1', /add a new organism/i
  end

  test 'non admin cannot get new' do
    login_as(:aaron)
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test 'admin has create organism menu option' do
    login_as(Factory(:admin))
    get :show, params: { id: Factory(:organism) }
    assert_response :success
    assert_select 'li#create-menu' do
      assert_select 'ul.dropdown-menu' do
        assert_select 'li a[href=?]', new_organism_path, text: 'Organism'
      end
    end
  end

  test 'project administrator has create organism menu option' do
    login_as(Factory(:project_administrator))
    get :show, params: { id: Factory(:organism) }
    assert_response :success
    assert_select 'li#create-menu' do
      assert_select 'ul.dropdown-menu' do
        assert_select 'li a[href=?]', new_organism_path, text: 'Organism'
      end
    end
  end

  test 'non admin doesn not have create organism menu option' do
    login_as(Factory(:user))
    get :show, params: { id: Factory(:organism) }
    assert_response :success
    assert_select 'li#create-menu' do
      assert_select 'ul.dropdown-menu' do
        assert_select 'li a[href=?]', new_organism_path, text: 'Organism', count: 0
      end
    end
  end

  test 'admin can create new organism' do
    login_as(:quentin)
    assert_difference('Organism.count') do
      post :create, params: { organism: { title: 'An organism' } }
    end
    assert_not_nil assigns(:organism)
    assert_redirected_to organism_path(assigns(:organism))
  end

  test 'create organism with concept uri' do
    login_as(:quentin)
    assert_difference('Organism.count') do
      post :create, params: { organism: { title: 'An organism', concept_uri:'https://identifiers.org/taxonomy/9606' } }
    end
    assert_not_nil assigns(:organism)

    #uri is converted the taxonomy form
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/9606',assigns(:organism).concept_uri
  end

  #should convert to the purl version
  test 'create organism with ncbi id number' do
    login_as(:quentin)
    assert_difference('Organism.count') do
      post :create, params: { organism: { title: 'An organism', concept_uri:'2222' } }
    end
    assert_not_nil assigns(:organism)
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2222',assigns(:organism).concept_uri
  end

  #should convert to the purl version
  test 'update organism with ncbi id number' do
    login_as(:quentin)
    org = Factory(:organism)
    patch :update, params: { id: org.id, organism: {concept_uri:'2222'} }
    assert_not_nil assigns(:organism)
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2222',assigns(:organism).concept_uri
  end

  test 'project administrator can create new organism' do
    login_as(Factory(:project_administrator))
    assert_difference('Organism.count') do
      post :create, params: { organism: { title: 'An organism' } }
    end
    assert_not_nil assigns(:organism)
    assert_redirected_to organism_path(assigns(:organism))
  end

  test 'programme administrator can create new organism' do
    login_as(Factory(:programme_administrator_not_in_project))
    assert_difference('Organism.count') do
      post :create, params: { organism: { title: 'An organism' } }
    end
    assert_not_nil assigns(:organism)
    assert_redirected_to organism_path(assigns(:organism))
  end

  test 'non admin cannot create new organism' do
    login_as(:aaron)
    assert_no_difference('Organism.count') do
      post :create, params: { organism: { title: 'An organism' } }
    end
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test 'delete button disabled for associated organisms' do
    login_as(:quentin)
    y = organisms(:yeast)
    get :show, params: { id: y }
    assert_response :success
    assert_select 'span.disabled_icon img', count: 1
    assert_select 'span.disabled_icon a', count: 0
  end

  test 'admin sees edit and create buttons' do
    login_as(:quentin)
    y = organisms(:human)
    get :show, params: { id: y }
    assert_response :success
    assert_select '#content a[href=?]', edit_organism_path(y), count: 1
    assert_select '#content a', text: /Edit Organism/, count: 1

    assert_select '#content a[href=?]', new_organism_path, count: 1
    assert_select '#content a', text: /Add Organism/, count: 1

    assert_select '#content a', text: /Delete Organism/, count: 1
  end

  test 'project administrator sees create buttons' do
    login_as(Factory(:project_administrator))
    y = organisms(:human)
    get :show, params: { id: y }
    assert_response :success

    assert_select '#content a[href=?]', new_organism_path, count: 1
    assert_select '#content a', text: /Add Organism/, count: 1
  end

  test 'non admin does not see edit, create and delete buttons' do
    login_as(:aaron)
    y = organisms(:human)
    get :show, params: { id: y }
    assert_response :success
    assert_select '#content a[href=?]', edit_organism_path(y), count: 0
    assert_select '#content a', text: /Edit Organism/, count: 0

    assert_select '#content a[href=?]', new_organism_path, count: 0
    assert_select '#content a', text: /Add Organism/, count: 0

    assert_select '#content a', text: /Delete Organism/, count: 0
  end

  test 'delete as admin' do
    login_as(:quentin)
    o = organisms(:human)
    assert_difference('Organism.count', -1) do
      delete :destroy, params: { id: o }
    end
    assert_redirected_to organisms_path
  end

  test 'delete as project administrator' do
    login_as(Factory(:project_administrator))
    o = organisms(:human)
    assert_difference('Organism.count', -1) do
      delete :destroy, params: { id: o }
    end
    assert_redirected_to organisms_path
  end

  test 'cannot delete as non-admin' do
    login_as(:aaron)
    o = organisms(:human)
    assert_no_difference('Organism.count') do
      delete :destroy, params: { id: o }
    end
    refute_nil flash[:error]
  end

  test 'visualise available when logged out' do
    logout
    o = Factory(:organism, bioportal_concept: Factory(:bioportal_concept))
    get :visualise, params: { id: o }
    assert_response :success
  end

  test 'cannot delete associated organism' do
    login_as(:quentin)
    o = organisms(:yeast)
    assert_no_difference('Organism.count') do
      delete :destroy, params: { id: o }
    end
  end

  test 'should list strains' do
    user = Factory :user
    login_as(user)
    organism = Factory :organism
    strain_a = Factory :strain, title: 'strainA', organism: organism
    parent_strain = Factory :strain
    strain_b = Factory :strain, title: 'strainB', parent: parent_strain, organism: organism

    get :show, params: { id: organism }
    assert_response :success
    assert_select 'table.strain_list' do
      assert_select 'tr', count: 2 do
        assert_select 'td > a[href=?]', strain_path(strain_a), text: strain_a.title
        assert_select 'td > a[href=?]', strain_path(strain_b), text: strain_b.title
        assert_select 'td > a[href=?]', strain_path(parent_strain), text: parent_strain.title
      end
    end
  end

  test 'strains cleaned up when organism deleted' do
    login_as(:quentin)
    organism = Factory(:organism)
    strains = FactoryGirl.create_list(:strain, 3, organism: organism, contributor: nil)

    assert_difference('Organism.count', -1) do
      assert_difference('Strain.count', -3) do
        delete :destroy, params: { id: organism }
      end
    end
  end

  test 'samples in related items' do
    person = Factory(:person)
    login_as(person.user)
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)
    organism = strain.organism

    sample = Sample.new(sample_type: sample_type, contributor: person, project_ids: [person.projects.first.id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)
    sample.save!

    get :show, params: { id: organism }

    assert_response :success
    assert_select 'div.related-items > ul > li > a', text: "Samples (1)"
    assert_select 'div.related-items .tab-pane a[href=?]', sample_path(sample), text: /#{sample.title}/
  end

  test 'create multiple organisms with blank concept uri' do
    login_as(Factory(:admin))
    assert_difference('Organism.count') do
      post :create, params: { organism: { title: 'An organism', concept_uri:'' } }
    end
    assert_not_nil assigns(:organism)
    assert_nil assigns(:organism).concept_uri

    assert_difference('Organism.count') do
      post :create, params: { organism: { title: 'An organism 2', concept_uri:'' } }
    end

    refute_nil assigns(:organism)
    assert_nil assigns(:organism).concept_uri
  end

  test 'project organisms through nested route' do
    assert_routing 'projects/3/organisms', controller: 'organisms', action: 'index', project_id: '3'

    o1 = Factory(:organism)
    o2 = Factory(:organism)

    p1 = Factory(:project,organisms:[o1])
    p2 = Factory(:project,organisms:[o2])

    refute_includes p1.organisms,o2

    o1.reload
    assert_includes o1.projects,p1
    refute_includes o1.projects,p2

    o2.reload
    assert_includes o2.projects,p2
    refute_includes o2.projects,p1

    get :index, params: { project_id:p1.id }

    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', organism_path(o1), text: o1.title
      assert_select 'a[href=?]', organism_path(o2), text: o2.title, count: 0
    end

  end

  test 'programme organisms through nested route' do
    assert_routing 'programmes/3/organisms', controller: 'organisms', action: 'index', programme_id: '3'

    o1 = Factory(:organism)
    o2 = Factory(:organism)

    p1 = Factory(:project,organisms:[o1],programme:Factory(:programme))
    p2 = Factory(:project,organisms:[o2],programme:Factory(:programme))

    refute_includes p1.organisms,o2

    o1.reload
    assert_includes o1.projects,p1
    refute_includes o1.projects,p2

    o2.reload
    assert_includes o2.projects,p2
    refute_includes o2.projects,p1

    refute_nil p1.programme
    refute_nil p2.programme

    get :index, params: { programme_id:p1.programme.id }

    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', organism_path(o1), text: o1.title
      assert_select 'a[href=?]', organism_path(o2), text: o2.title, count: 0
    end

  end

  test 'publication organisms through nested route' do
    assert_routing 'publications/3/organisms', controller: 'organisms', action: 'index', publication_id: '3'

    o1 = Factory(:organism)
    o2 = Factory(:organism)
    a1 = Factory(:assay,organisms:[o1])
    a2 = Factory(:assay,organisms:[o2])
    pub1 = Factory(:publication, assays:[a1])
    pub2 = Factory(:publication, assays:[a2])

    assert_equal [o1],pub1.related_organisms
    assert_equal [o2],pub2.related_organisms

    o1.reload
    assert_equal [pub1],o1.related_publications

    get :index, params: { publication_id:pub1.id }

    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', organism_path(o1), text: o1.title
      assert_select 'a[href=?]', organism_path(o2), text: o2.title, count: 0
    end

  end

  test 'assay organisms through nested route' do
    assert_routing 'assays/3/organisms', controller: 'organisms', action: 'index', assay_id: '3'

    o1 = Factory(:organism)
    o2 = Factory(:organism)


    a1 = Factory(:assay,organisms:[o1])
    a2 = Factory(:assay,organisms:[o2])


    get :index, params: { assay_id:a1 }

    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', organism_path(o1), text: o1.title
      assert_select 'a[href=?]', organism_path(o2), text: o2.title, count: 0
    end

  end

end

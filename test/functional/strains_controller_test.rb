require 'test_helper'

class StrainsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include RdfTestCases
  include GeneralAuthorizationTestCases
  include HtmlHelper

  def setup
    login_as :owner_of_fully_public_policy
  end

  def rest_api_test_object
    @object = Factory(:strain, organism_id: Factory(:organism, bioportal_concept: Factory(:bioportal_concept)).id)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:strains)
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:strain)
  end

  test 'should create' do
    assert_difference('Strain.count') do
      post :create, params: { strain: { title: 'strain 1',
                              organism_id: Factory(:organism).id,
                              project_ids: [Factory(:project).id] } }
    end
    s = assigns(:strain)
    assert_redirected_to strain_path(s)
    assert_equal 'strain 1', s.title
  end

  test 'should get show' do
    get :show, params: { id: Factory(:strain,
                           title: 'strain 1',
                           policy: policies(:editing_for_all_sysmo_users_policy)) }
    assert_response :success
    assert_not_nil assigns(:strain)
  end

  test 'should get edit' do
    get :edit, params: { id: Factory(:strain, policy: policies(:editing_for_all_sysmo_users_policy)) }
    assert_response :success
    assert_not_nil assigns(:strain)
  end

  test 'should update' do
    strain = Factory(:strain, title: 'strain 1', policy: policies(:editing_for_all_sysmo_users_policy))
    project = Factory(:project)
    assert_not_equal 'test', strain.title
    assert !strain.projects.include?(project)
    put :update, params: { id: strain.id, strain: { title: 'test', project_ids: [project.id] } }
    s = assigns(:strain)
    assert_redirected_to strain_path(s)
    assert_equal 'test', s.title
    assert s.projects.include?(project)
  end

  test 'should destroy' do
    s = Factory :strain, contributor: User.current_user.person
    assert_difference('Strain.count', -1, 'A strain should be deleted') do
      delete :destroy, params: { id: s.id }
    end
  end

  test 'unauthorized users cannot add new strain' do
    login_as Factory(:user, person: Factory(:brand_new_person))
    get :new
    assert_response :redirect
  end

  test 'unauthorized user cannot edit strain' do
    login_as Factory(:user, person: Factory(:brand_new_person))
    s = Factory :strain, policy: Factory(:private_policy)
    get :edit, params: { id: s.id }
    assert_redirected_to strain_path(s)
    assert flash[:error]
  end
  test 'unauthorized user cannot update strain' do
    login_as Factory(:user, person: Factory(:brand_new_person))
    s = Factory :strain, policy: Factory(:private_policy)

    put :update, params: { id: s.id, strain: { title: 'test' } }
    assert_redirected_to strain_path(s)
    assert flash[:error]
  end

  test 'unauthorized user cannot delete strain' do
    login_as Factory(:user, person: Factory(:brand_new_person))
    s = Factory :strain, policy: Factory(:private_policy)
    assert_no_difference('Strain.count') do
      delete :destroy, params: { id: s.id }
    end
    assert flash[:error]
    assert_redirected_to s
  end

  test 'contributor can delete strain' do
    s = Factory :strain, contributor: User.current_user.person
    assert_difference('Strain.count', -1, 'A strain should be deleted') do
      delete :destroy, params: { id: s.id }
    end

    s = Factory :strain, policy: Factory(:publicly_viewable_policy)
    assert_no_difference('Strain.count') do
      delete :destroy, params: { id: s.id }
    end
    assert flash[:error]
    assert_redirected_to s
  end

  test 'should update genotypes and phenotypes' do
    strain = Factory(:strain)
    genotype1 = Factory(:genotype, strain: strain)
    genotype2 = Factory(:genotype, strain: strain)

    phenotype1 = Factory(:phenotype, strain: strain)
    phenotype2 = Factory(:phenotype, strain: strain)

    new_gene_title = 'new gene'
    new_modification_title = 'new modification'
    new_phenotype_description = 'new phenotype'
    login_as(strain.contributor)
    # [genotype1,genotype2] =>[genotype2,new genotype]
    put :update, params: { id: strain.id, strain: {
                   genotypes_attributes: { '0' => { gene_attributes: { title: genotype2.gene.title, id: genotype2.gene.id }, id: genotype2.id, modification_attributes: { title: genotype2.modification.title, id: genotype2.modification.id } },
                                           '2' => { gene_attributes: { title: new_gene_title }, modification_attributes: { title: new_modification_title } },
                                           '1' => { id: genotype1.id, _destroy: 1 } },
                   phenotypes_attributes: { '0' => { description: phenotype2.description, id: phenotype2.id }, '2343243' => { id: phenotype1.id, _destroy: 1 }, '1' => { description: new_phenotype_description } }
                 } }
    assert_redirected_to strain_path(strain)

    updated_strain = Strain.find_by_id strain.id
    new_gene = Gene.find_by_title(new_gene_title)
    new_modification = Modification.find_by_title(new_modification_title)
    new_genotype = Genotype.where(gene_id: new_gene.id, modification_id: new_modification.id).first
    new_phenotype = Phenotype.where(description: new_phenotype_description).sort_by(&:created_at).last
    updated_genotypes = [genotype2, new_genotype].sort_by(&:id)
    assert_equal updated_genotypes, updated_strain.genotypes.sort_by(&:id)

    updated_phenotypes = [phenotype2, new_phenotype].sort_by(&:id)
    assert_equal updated_phenotypes, updated_strain.phenotypes.sort_by(&:id)
  end

  test 'should not be able to update the policy of the strain when having no manage rights' do
    strain = Factory(:strain, policy: Factory(:policy, access_type: Policy::EDITING))
    user = Factory(:user)
    assert strain.can_edit? user
    assert !strain.can_manage?(user)

    login_as(user)
    put :update, params: { id: strain.id, strain: { title: strain.title }, policy_attributes: { access_type: Policy::MANAGING } }
    assert_redirected_to strain_path(strain)

    updated_strain = Strain.find_by_id strain.id
    assert_equal Policy::EDITING, updated_strain.policy.access_type
  end

  test 'should not be able to update the permissions of the strain when having no manage rights' do
    strain = Factory(:strain, policy: Factory(:policy, access_type: Policy::EDITING))
    user = Factory(:user)
    assert strain.can_edit? user
    assert !strain.can_manage?(user)

    login_as(user)
    put :update, params: { id: strain.id, strain: { title: strain.title }, policy_attributes: { permissions_attributes: {
                   '1' => { contributor_type: 'Person', contributor_id: user.person.id, access_type: Policy::MANAGING }
                 } } }
    assert_redirected_to strain_path(strain)

    updated_strain = Strain.find_by_id strain.id
    assert updated_strain.policy.permissions.empty?
    assert !updated_strain.can_manage?(user)
  end

  test 'strains filtered by assay through nested route' do
    assert_routing 'assays/5/strains', controller: 'strains', action: 'index', assay_id: '5'
    ao1 = Factory(:assay_organism, strain: Factory(:strain, policy: Factory(:public_policy)))
    ao2 = Factory(:assay_organism, strain: Factory(:strain, policy: Factory(:public_policy)))
    strain1 = ao1.strain
    strain2 = ao2.strain
    assay1 = ao1.assay
    assay2 = ao2.assay

    refute_nil strain1
    refute_nil strain2
    refute_equal strain1, strain2
    refute_nil assay1
    refute_nil assay2
    refute_equal assay1, assay2

    assert_includes assay1.strains, strain1
    assert_includes assay2.strains, strain2

    assert_includes strain1.assays, assay1
    assert_includes strain2.assays, assay2

    assert strain1.can_view?
    assert strain2.can_view?

    get :index, params: { assay_id: assay1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', strain_path(strain1), text: strain1.title
      assert_select 'a[href=?]', strain_path(strain2), text: strain2.title, count: 0
    end
  end

  test 'strains filtered by project through nested route' do
    assert_routing 'projects/5/strains', controller: 'strains', action: 'index', project_id: '5'
    strain1 = Factory(:strain, policy: Factory(:public_policy))
    strain2 = Factory(:strain, policy: Factory(:public_policy))

    refute_empty strain1.projects
    refute_empty strain2.projects
    refute_equal strain1.projects.first, strain2.projects.first

    get :index, params: { project_id: strain1.projects.first.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', strain_path(strain1), text: strain1.title
      assert_select 'a[href=?]', strain_path(strain2), text: strain2.title, count: 0
    end
  end

  test 'strains filtered by person through nested route' do
    assert_routing 'people/5/strains', controller: 'strains', action: 'index', person_id: '5'
    person1 = Factory(:person)
    person2 = Factory(:person)
    strain1 = Factory(:strain, policy: Factory(:public_policy),contributor:person1)
    strain2 = Factory(:strain, policy: Factory(:public_policy),contributor:person2)


    get :index, params: { person_id: person1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', strain_path(strain1), text: strain1.title
      assert_select 'a[href=?]', strain_path(strain2), text: strain2.title, count: 0
    end
  end

  test 'should create log and send email to gatekeeper when request to publish a strain' do
    strain_in_gatekept_project = { title: 'Test', project_ids: [Factory(:asset_gatekeeper).projects.first.id], organism_id: Factory(:organism).id }
    assert_difference ('ResourcePublishLog.count') do
      assert_enqueued_emails 1 do
        post :create, params: { strain: strain_in_gatekept_project, policy_attributes: { access_type: Policy::VISIBLE } }
      end
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, publish_log.publish_state.to_i
    strain = assigns(:strain)
    assert_equal strain, publish_log.resource
    assert_equal strain.contributor.user, publish_log.user
  end

  test 'should fill in the based-on strain if chosen' do
    strain = Factory(:strain,
                     genotypes: [Factory(:genotype)],
                     phenotypes: [Factory(:phenotype)])

    get :new, params: { parent_id: strain.id }
    assert_response :success

    assert_select 'input[id=?][value=?]', 'strain_title', strain.title
    assert_select 'select[id=?]', 'strain_parent_id' do
      assert_select "option[value='#{strain.id}'][selected]", text: strain.info
    end
    assert_select 'select[id=?]', 'strain_organism_id' do
      assert_select "option[value='#{strain.organism.id}'][selected]", text: strain.organism.title
    end
    genotype = strain.genotypes.first
    phenotype = strain.phenotypes.first

    genotypes = JSON.parse(select_node_contents('#existing-genotypes'))
    phenotypes = JSON.parse(select_node_contents('#existing-phenotypes'))

    assert_equal 1, genotypes.length
    assert_equal 1, phenotypes.length
    assert genotypes.any? { |g| g['item']['gene'] == genotype.gene.title }
    assert genotypes.any? { |g| g['item']['modification'] == genotype.modification.title }
    assert phenotypes.any? { |p| p['item']['description'] == phenotype.description }
  end

  test 'authorization for based-on strain' do
    unauthorized_parent_strain = Factory(:strain,
                                         policy: Factory(:private_policy))
    assert !unauthorized_parent_strain.can_view?

    get :new, params: { parent_id: unauthorized_parent_strain.id }
    assert_response :success

    assert_select 'input[id=?][value=?]', 'strain_title', unauthorized_parent_strain.title, count: 0

    authorized_parent_strain = Factory(:strain)
    assert authorized_parent_strain.can_view?

    get :new, params: { parent_id: authorized_parent_strain.id }
    assert_response :success

    assert_select 'input[id=?][value=?]', 'strain_title', authorized_parent_strain.title
  end

  test 'shows related samples on show page' do
    person = Factory(:person)
    login_as(person.user)
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    samples = 3.times.map do |i|
      sample = Sample.new(sample_type: sample_type, contributor: person, project_ids: [person.projects.first.id])
      sample.set_attribute(:name, "Strain sample #{i}")
      sample.set_attribute(:seekstrain, strain.id)
      sample.save!

      sample
    end

    with_config_value(:related_items_limit, 2) do
      get :show, params: { id: strain }

      assert_response :success

      assert_select 'div.related-items a[href*=?]', samples_path, text: /Strain sample \d/, count: 2
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('strain')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    strain = Factory(:strain, contributor:person)
    login_as(person)
    assert strain.can_manage?
    get :manage, params: {id: strain}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:0

    assert_select 'div#author_form', count:0
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    strain = Factory(:strain, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert strain.can_edit?
    refute strain.can_manage?
    get :manage, params: {id:strain}
    assert_redirected_to strain
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person,project:proj1)
    other_person = Factory(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    strain = Factory(:strain, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert strain.can_manage?

    patch :manage_update, params: {id: strain,
                                   strain: {
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to strain

    strain.reload
    assert_equal [proj1,proj2],strain.projects.sort_by(&:id)
    assert_equal Policy::VISIBLE,strain.policy.access_type
    assert_equal 1,strain.policy.permissions.count
    assert_equal other_person,strain.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,strain.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = Factory(:person)


    strain = Factory(:strain, projects:[proj1], policy:Factory(:private_policy,
                                                               permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute strain.can_manage?
    assert strain.can_edit?

    assert_equal [proj1],strain.projects

    patch :manage_update, params: {id: strain,
                                   strain: {
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    strain.reload
    assert_equal [proj1],strain.projects
    assert_equal Policy::PRIVATE,strain.policy.access_type
    assert_equal 1,strain.policy.permissions.count
    assert_equal person,strain.policy.permissions.first.contributor
    assert_equal Policy::EDITING,strain.policy.permissions.first.access_type

  end
end

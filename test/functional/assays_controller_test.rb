require 'test_helper'

class AssaysControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include RdfTestCases
  include GeneralAuthorizationTestCases
  include HtmlHelper

  def setup
    login_as(:quentin)
  end

  def test_title
    get :index
    assert_select 'title', text: I18n.t('assays.assay').pluralize, count: 1
  end

  test 'add model button' do
    # should show for modelling analysis but not experimental
    person = FactoryBot.create(:person)
    login_as(person)
    exp = FactoryBot.create(:experimental_assay, contributor:person)
    mod = FactoryBot.create(:modelling_assay, contributor: person)

    assert exp.is_experimental?
    assert mod.is_modelling?

    assert exp.can_edit?
    assert mod.can_edit?


    get :show, params: { id: exp.id }
    assert_response :success
    assert_select "a[href=?]",new_model_path('model[assay_assets_attributes[][assay_id]]'=>exp.id),text:/#{I18n.t('add_new_dropdown.option')} Model/, count:0
    assert_select "a[href=?]",new_data_file_path('data_file[assay_assets_attributes[][assay_id]]'=>exp.id),text:/#{I18n.t('add_new_dropdown.option')} Data file/

    get :show, params: { id: mod.id }
    assert_response :success
    assert_select "a[href=?]",new_model_path('model[assay_assets_attributes[][assay_id]]'=>mod.id),text:/#{I18n.t('add_new_dropdown.option')} Model/
    assert_select "a[href=?]",new_data_file_path('data_file[assay_assets_attributes[][assay_id]]'=>mod.id),text:/#{I18n.t('add_new_dropdown.option')} Data file/

  end


  test 'should show index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:assays)
  end

  test 'should show draggable icon in index' do
    get :index
    assert_response :success
    assays = assigns(:assays)
    first_assay = assays.first
    assert_not_nil first_assay
    assert_select 'a[data-favourite-url=?]', add_favourites_path(resource_id: first_assay.id,
                                                                 resource_type: first_assay.class.name)
  end

  test 'should show index in xml' do
    get :index
    assert_response :success
    assert_not_nil assigns(:assays)
  end

  test 'should update assay with new version of same sop' do
    login_as(:model_owner)
    assay = assays(:metabolomics_assay)

    sop = sops(:sop_with_all_sysmo_users_policy)
    assert !assay.sops.include?(sop.latest_version)
    assert_difference('ActivityLog.count') do
      put :update, params: { id: assay, assay: { sop_ids: [sop.id], title: assay.title } }
      assert_redirected_to assay_path(assay)
    end

    assert_redirected_to assay_path(assay)
    assert assigns(:assay)

    assay.reload
    stored_sop_assay_asset = assay.assay_assets.detect { |aa| aa.asset == sop }
    assert_equal sop.version, stored_sop_assay_asset.version

    login_as sop.contributor
    sop.save_as_new_version
    login_as(:model_owner)

    assert_difference('ActivityLog.count') do
      put :update, params: { id: assay, assay: { sop_ids: [sop.id], title: assay.title } }
      assert_redirected_to assay_path(assay)
    end

    assay.reload
    assert_equal sop.version, stored_sop_assay_asset.reload.version
  end

  test 'should update timestamp when associating sop' do
    login_as(:model_owner)
    assay = assays(:metabolomics_assay)
    timestamp = assay.updated_at

    sop = sops(:sop_with_all_sysmo_users_policy)
    assert !assay.sops.include?(sop.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, params: { id: assay, assay: { sop_ids: [sop.id], title: assay.title } }
    end

    assert_redirected_to assay_path(assay)
    assert assigns(:assay)
    updated_assay = Assay.find(assay.id)

    assert_not_equal timestamp, updated_assay.updated_at
  end

  test 'should update timestamp when associating datafile' do
    login_as(:model_owner)
    assay = assays(:metabolomics_assay)
    timestamp = assay.updated_at

    df = data_files(:downloadable_data_file)
    assert !assay.data_files.include?(df.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, params: { id: assay, assay: { data_file_attributes: [{ asset_id: df.id, relationship_type_id: RelationshipType.find_by_title('Test data').id }], title: assay.title } }
    end

    assert_redirected_to assay_path(assay)
    assert assigns(:assay)
    updated_assay = Assay.find(assay.id)

    assert_not_equal timestamp, updated_assay.updated_at
  end

  test 'should update timestamp when associating model' do
    person = FactoryBot.create(:person)
    login_as(person.user)
    assay = FactoryBot.create(:modelling_assay, contributor:person)
    timestamp = assay.updated_at

    model = FactoryBot.create(:model, contributor:person)
    assert !assay.models.include?(model.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, params: { id: assay, assay: { model_ids: [model.id], title: assay.title } }
    end

    assert_redirected_to assay_path(assay)
    assert assigns(:assay)
    updated_assay = Assay.find(assay.id)

    assert_not_equal timestamp, updated_assay.updated_at
  end

  test 'should show item' do
    assay = FactoryBot.create(:experimental_assay, policy: FactoryBot.create(:public_policy),
                                         assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Catabolic_response',
                                         technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Binding')
    assert_difference('ActivityLog.count') do
      get :show, params: { id: assay.id }
    end

    assert_response :success

    assert_not_nil assigns(:assay)

    assert_select 'p#assay_type', text: /Catabolic response/, count: 1
    assert_select 'p#technology_type', text: /Binding/, count: 1
  end

  test 'should show modelling assay' do
    assert_difference('ActivityLog.count') do
      get :show, params: { id: assays(:modelling_assay_with_data_and_relationship) }
    end

    assert_response :success
    assert_not_nil assigns(:assay)
    assert_equal assigns(:assay), assays(:modelling_assay_with_data_and_relationship)
  end

  test 'should show new' do
    # adding a suggested type tests the assay type tree handles inclusion of suggested type
    FactoryBot.create :suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Catabolic_response'
    get :new
    assert_response :success
    assert_not_nil assigns(:assay)
    assert_nil assigns(:assay).study
    assert_select 'div.alert.alert-info', text: /No Study and Investigation available/, count: 0
    assert_select 'a.btn[href=?]', new_investigation_path, count: 0
  end

  test 'should show new with study when id provided' do
    s = studies(:metabolomics_study)
    get :new, params: {assay: { study_id: s.id }}
    assert_response :success
    assert_not_nil assigns(:assay)
    assert_equal s, assigns(:assay).study
  end

  test 'should show item with no study' do
    assert_difference('ActivityLog.count') do
      get :show, params: { id: assays(:assay_with_no_study_or_files) }
    end

    assert_response :success
    assert_not_nil assigns(:assay)
  end

  test 'should update with study' do
    login_as(:model_owner)
    a = assays(:assay_with_no_study_or_files)
    s = studies(:metabolomics_study)
    assert_difference('ActivityLog.count') do
      put :update, params: { id: a, assay: { study_id: s } }
    end

    assert_redirected_to assay_path(a)
    assert assigns(:assay)
    assert_not_nil assigns(:assay).study
    assert_equal s, assigns(:assay).study
  end

  test 'should create modelling assay with/without organisms' do
    assert_difference('Assay.count') do
      post :create, params: { assay: { title: 'test',
                             study_id: FactoryBot.create(:study,contributor:User.current_user.person).id,
                             assay_class_id: assay_classes(:modelling_assay_class).id }, policy_attributes: valid_sharing }
    end

    assay = assigns(:assay)
    refute_nil assay
    assert assay.organisms.empty?
    assert assay.strains.empty?

    organism = FactoryBot.create(:organism, title: 'Frog')
    strain = FactoryBot.create(:strain, title: 'UUU', organism: organism)
    growth_type = FactoryBot.create(:culture_growth_type, title: 'batch')
    assert_difference('Assay.count') do
      post :create, params: { assay: { title: 'test',
                             study_id: FactoryBot.create(:study,contributor:User.current_user.person).id,
                             assay_class_id: assay_classes(:modelling_assay_class).id }, assay_organism_ids: [organism.id, strain.title, strain.id, growth_type.title].join(','), policy_attributes: valid_sharing }
    end
    a = assigns(:assay)
    assert_equal 1, a.assay_organisms.count
    assert_includes a.organisms, organism
    assert_includes a.strains, strain
    assert_redirected_to assay_path(a)
  end

  test 'should create assay with ontology assay and tech type' do
    assert_difference('Assay.count') do
      post :create, params: { assay: { title: 'test',
                             technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography',
                             assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics',
                             study_id: FactoryBot.create(:study,contributor:User.current_user.person).id,
                             assay_class_id: FactoryBot.create(:experimental_assay_class).id }, policy_attributes: valid_sharing }
    end
    assert assigns(:assay)
    assay = assigns(:assay)
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography', assay.technology_type_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Metabolomics', assay.assay_type_uri
    assert_equal 'Gas chromatography', assay.technology_type_label
    assert_equal 'Metabolomics', assay.assay_type_label
  end

  test 'should create assay with suggested assay and tech type' do
    assay_type = FactoryBot.create(:suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics', label: 'fish')
    tech_type = FactoryBot.create(:suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography', label: 'carrot')
    assert_difference('Assay.count') do
      post :create, params: { assay: { title: 'test',
                             technology_type_uri: tech_type.uri,
                             assay_type_uri: assay_type.uri,
                             study_id: FactoryBot.create(:study,contributor:User.current_user.person).id,
                             assay_class_id: FactoryBot.create(:experimental_assay_class).id }, policy_attributes: valid_sharing }
    end
    assert assigns(:assay)
    assay = assigns(:assay)
    assert_equal assay_type, assay.suggested_assay_type
    assert_equal tech_type, assay.suggested_technology_type
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography', assay.technology_type_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Metabolomics', assay.assay_type_uri
    assert_equal 'carrot', assay.technology_type_label
    assert_equal 'fish', assay.assay_type_label
  end

  test 'create a assay with extended metadata' do
    cmt = FactoryBot.create(:simple_assay_extended_metadata_type)
    login_as(FactoryBot.create(:person))
    assert_difference('Assay.count') do

      assay_attributes = { title: 'test',
                           study_id: FactoryBot.create(:study,contributor:User.current_user.person).id,
                           assay_class_id: assay_classes(:modelling_assay_class).id }
      cm_attributes = {extended_metadata_attributes:{extended_metadata_type_id: cmt.id,
                                                   data:{'name':'fred','age':22}}}
       post :create, params: { assay: assay_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert assay=assigns(:assay)
    assert cm = assay.extended_metadata
    assert_equal cmt, cm.extended_metadata_type
    assert_equal 'fred',cm.get_attribute_value('name')
    assert_equal 22,cm.get_attribute_value('age')
    assert_nil cm.get_attribute_value('date')
  end

  test 'create a assay with extended metadata validated' do
    cmt = FactoryBot.create(:simple_assay_extended_metadata_type)
    login_as(FactoryBot.create(:person))

    assert_no_difference('Assay.count') do
      assay_attributes = { title: 'test',
                           study_id: FactoryBot.create(:study,contributor:User.current_user.person).id,
                           assay_class_id: assay_classes(:modelling_assay_class).id }
      cm_attributes = {extended_metadata_attributes:{extended_metadata_type_id: cmt.id, data:{'name':'fred','age':'not a number'}}}


      post :create, params: { assay: assay_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert assay=assigns(:assay)
    refute assay.valid?

    assert_no_difference('Assay.count') do
      assay_attributes = { title: 'test',
                           study_id: FactoryBot.create(:study,contributor:User.current_user.person).id,
                           assay_class_id: assay_classes(:modelling_assay_class).id }
      cm_attributes = {extended_metadata_attributes:{extended_metadata_type_id: cmt.id, data:{'name':nil,'age':22}}}

      post :create, params: { assay: assay_attributes.merge(cm_attributes), sharing: valid_sharing }
    end
    assert assay=assigns(:assay)
    refute assay.valid?
  end

  test 'should update assay with suggested assay and tech type' do
    assay = FactoryBot.create(:experimental_assay, contributor: User.current_user.person)
    assay_type = FactoryBot.create(:suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics', label: 'fish')
    tech_type = FactoryBot.create(:suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography', label: 'carrot')

    post :update, params: { id: assay.id, assay: {
      technology_type_uri: tech_type.uri,
      assay_type_uri: assay_type.uri
    }, policy_attributes: valid_sharing }

    assay.reload
    assert_equal assay_type, assay.suggested_assay_type
    assert_equal tech_type, assay.suggested_technology_type
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography', assay.technology_type_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Metabolomics', assay.assay_type_uri
    assert_equal 'fish', assay.assay_type_label
    assert_equal 'carrot', assay.technology_type_label
  end

  test 'should clear suggested assay and tech types when updating with a URI' do
    suggested_assay_type = FactoryBot.create(:suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics', label: 'fish')
    suggested_tech_type = FactoryBot.create(:suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography', label: 'carrot')
    assay = FactoryBot.create(:experimental_assay,
                    assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics',
                    technology_type_uri:'http://jermontology.org/ontology/JERMOntology#Gas_chromatography',
                    suggested_assay_type:suggested_assay_type,
                    suggested_technology_type:suggested_tech_type,
                    contributor:User.current_user.person)

    refute_nil assay.suggested_assay_type
    refute_nil assay.suggested_technology_type
    refute_nil assay.assay_type_uri
    refute_nil assay.technology_type_uri

    post :update, params: { id: assay.id, assay: {
        technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography',
        assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics'
    }, policy_attributes: valid_sharing }

    assay.reload
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Metabolomics',assay.assay_type_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography',assay.technology_type_uri
    assert_nil assay.suggested_assay_type
    assert_nil assay.suggested_technology_type

  end

  test 'should delete assay with study' do
    a = assays(:assay_with_just_a_study)
    login_as(:model_owner)
    assert_difference('ActivityLog.count') do
      assert_difference('Assay.count', -1) do
        delete :destroy, params: { id: a }
      end
    end

    assert_nil flash[:error]
    assert_redirected_to assays_path
  end

  test 'should not delete assay when not project member' do
    a = assays(:assay_with_just_a_study)
    login_as(:aaron)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, params: { id: a }
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test 'should not delete assay when not project pal' do
    a = assays(:assay_with_just_a_study)
    login_as(:datafile_owner)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, params: { id: a }
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test 'should list correct organisms' do
    a = FactoryBot.create :assay, policy: FactoryBot.create(:public_policy)
    o1 = FactoryBot.create(:organism, title: 'Frog')

    FactoryBot.create :assay_organism, assay: a, organism: o1

    get :show, params: { id: a.id }
    assert_response :success

    assert_select 'p#organism' do
      assert_select 'a[href=?]', organism_path(o1), text: 'Frog'
    end

    o2 = FactoryBot.create(:organism, title: 'Slug')
    str = FactoryBot.create :strain, title: 'AAA111', organism: o2
    FactoryBot.create :assay_organism, assay: a, organism: o2, strain: str
    get :show, params: { id: a.id }
    assert_response :success
    assert_select 'p#organism' do
      assert_select 'a[href=?]', organism_path(o1), text: 'Frog'
      assert_select 'a[href=?]', organism_path(o2), text: 'Slug'
      assert_select 'a.strain_info', text: str.info
    end
  end

  test 'should show edit when not logged in' do
    logout
    a = FactoryBot.create :experimental_assay, contributor: FactoryBot.create(:person), policy: FactoryBot.create(:editing_public_policy)
    get :edit, params: { id: a }
    assert_response :success

    a = FactoryBot.create :modelling_assay, contributor: FactoryBot.create(:person), policy: FactoryBot.create(:editing_public_policy)
    get :edit, params: { id: a }
    assert_response :success
  end

  test 'should not show delete button if not authorized to delete but can edit' do
    person = FactoryBot.create :person
    a = FactoryBot.create :assay, contributor: person, policy: FactoryBot.create(:public_policy, access_type: Policy::EDITING)
    assert !a.can_manage?
    assert a.can_view?
    get :show, params: { id: a.id }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'li' do
        assert_select 'span', text: /Delete/, count: 0
      end
    end
  end

  test 'should show delete button in disable state if authorized to delete but has associated items' do
    person = FactoryBot.create :person
    a = FactoryBot.create :assay, contributor: person, policy: FactoryBot.create(:public_policy)
    df = FactoryBot.create :data_file, contributor: person, policy: FactoryBot.create(:public_policy)
    FactoryBot.create :assay_asset, assay: a, asset: df
    a.reload
    assert a.can_manage?
    assert_equal 1, a.assets.count
    assert !a.can_delete?
    get :show, params: { id: a.id }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'li' do
        assert_select 'span.disabled_icon', text: /Delete/, count: 1
      end
    end
  end

  test 'should show delete button in enabled state if authorized delete and has no associated items' do
    person = FactoryBot.create :person
    a = FactoryBot.create :assay, contributor: person, policy: FactoryBot.create(:public_policy)

    assert a.can_manage?
    assert a.can_delete?
    get :show, params: { id: a.id }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'li' do
        assert_select 'a', text: /Delete/, count: 1
        assert_select 'span.disabled_icon', text: /Delete/, count: 0
      end
    end
  end

  test 'should not edit assay when not project pal' do
    a = assays(:assay_with_just_a_study)
    login_as(:datafile_owner)
    get :edit, params: { id: a }
    assert flash[:error]
    assert_redirected_to a
  end

  test 'admin should not edit somebody elses assay' do
    a = assays(:assay_with_just_a_study)
    login_as(:quentin)
    get :edit, params: { id: a }
    assert flash[:error]
    assert_redirected_to a
  end

  test 'should not delete assay with data files' do
    login_as(:model_owner)
    a = assays(:assay_with_no_study_but_has_some_files)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, params: { id: a }
      end
    end
    assert flash[:error]
    assert_redirected_to a
  end

  test 'should not delete assay with model' do
    login_as(:model_owner)
    a = assays(:assay_with_a_model)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, params: { id: a }
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test 'should not delete assay with publication' do
    login_as(FactoryBot.create(:user))
    one_assay_with_publication = FactoryBot.create :assay, contributor: User.current_user.person, publications: [FactoryBot.create(:publication)]

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, params: { id: one_assay_with_publication.id }
      end
    end

    assert flash[:error]
    assert_redirected_to one_assay_with_publication
  end

  test 'should not delete assay with sops' do
    login_as(:model_owner)
    a = assays(:assay_with_no_study_but_has_some_sops)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, params: { id: a }
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test 'get new presents options for class' do
    login_as(:model_owner)
    get :new
    assert_response :success
    assert_select 'a[href=?]', new_assay_path(class: 'EXP'), count: 1
    assert_select 'a', text: /An #{I18n.t('assays.experimental_assay')}/i, count: 1
    assert_select 'a[href=?]', new_assay_path(class: 'MODEL'), count: 1
    assert_select 'a', text: /A #{I18n.t('assays.modelling_analysis')}/i, count: 1
  end

  test 'get new with class doesnt present options for class' do
    login_as(:model_owner)
    get :new, params: { class: 'EXP' }
    assert_response :success
    assert_select 'a[href=?]', new_assay_path(class: 'EXP'), count: 0
    assert_select 'a', text: /An #{I18n.t('assays.experimental_assay')}/i, count: 0
    assert_select 'a[href=?]', new_assay_path(class: 'MODEL'), count: 0
    assert_select 'a', text: /A #{I18n.t('assays.modelling_analysis')}/i, count: 0

    get :new, params: { class: 'MODEL' }
    assert_response :success
    assert_select 'a[href=?]', new_assay_path(class: 'EXP'), count: 0
    assert_select 'a', text: /An #{I18n.t('assays.experimental_assay')}/i, count: 0
    assert_select 'a[href=?]', new_assay_path(class: 'MODEL'), count: 0
    assert_select 'a', text: /A #{I18n.t('assays.modelling_analysis')}/i, count: 0
  end

  test 'get new without investigation prompts user to create' do
    disable_authorization_checks { Investigation.destroy_all }
    FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    assert Investigation.authorized_for('view', User.current_user).none?

    get :new
    assert_response :success
    assert_select 'div.alert.alert-info', text: /No Study and Investigation available/, count: 1
    assert_select 'a.btn[href=?]', new_investigation_path
  end

  test 'get new without study prompts user to create' do
    disable_authorization_checks { Study.destroy_all }
    FactoryBot.create(:study, policy: FactoryBot.create(:private_policy))
    assert Study.authorized_for('view', User.current_user).none?

    get :new
    assert_response :success
    assert_select 'div.alert.alert-info', text: /No Study available/, count: 1
    assert_select 'a.btn[href=?]', new_study_path
  end

  test 'links have nofollow in sop tabs' do
    assay = FactoryBot.create(:assay, contributor:User.current_user.person)
    sop = FactoryBot.create(:sop,description:'http://news.bbc.co.uk',assays:[assay],contributor: User.current_user.person)
    assert_difference('ActivityLog.count') do
      get :show, params: { id: assay }
    end

    assert_select 'div.list_item div.list_item_desc' do
      assert_select 'a[rel=?]', 'nofollow', text: /news\.bbc\.co\.uk/, minimum: 1
    end
  end

  test 'links have nofollow in data_files tabs' do
    login_as(:owner_of_my_first_sop)
    data_file_version = data_files(:picture)
    data_file_version.description = 'http://news.bbc.co.uk'
    data_file_version.save!
    assert_difference('ActivityLog.count') do
      get :show, params: { id: assays(:metabolomics_assay) }
    end

    assert_select 'div.list_item div.list_item_desc' do
      assert_select 'a[rel=?]', 'nofollow', text: /news\.bbc\.co\.uk/, minimum: 1
    end
  end

  def test_should_add_nofollow_to_links_in_show_page
    assert_difference('ActivityLog.count') do
      get :show, params: { id: assays(:assay_with_links_in_description) }
    end

    assert_select 'div#description' do
      assert_select 'a[rel="nofollow"]'
    end
  end

  test 'should not allow XSS in descriptions' do
    assay = FactoryBot.create(:assay, description: 'hello <script>alert("HELLO")</script>')
    get :show, params: { id: assays(:assay_with_links_in_description) }

    assert_select 'div#description' do
      assert_select 'script', count: 0
    end
  end

  # checks that for an assay that has 2 sops and 2 datafiles, of which 1 is public and 1 private - only links to the public sops & datafiles are show
  def test_authorization_of_sops_and_datafiles_links
    # sanity check the fixtures are correct
    check_fixtures_for_authorization_of_sops_and_datafiles_links
    login_as(:model_owner)
    assay = assays(:assay_with_public_and_private_sops_and_datafiles)
    assert_difference('ActivityLog.count') do
      get :show, params: { id: assay.id }
    end

    assert_response :success

    assert_select 'ul.nav-pills' do
      assert_select 'a', text: "#{I18n.t('sop').pluralize} (1+1)", count: 1
      assert_select 'a', text: "#{I18n.t('data_file').pluralize} (1+1)", count: 1
    end

    assert_select 'div.list_item' do
      assert_select 'div.list_item_title a[href=?]', sop_path(sops(:sop_with_fully_public_policy)), text: 'SOP with fully public policy', count: 1
      assert_select 'div.list_item_actions a[href=?]', download_sop_path(sops(:sop_with_fully_public_policy)), count: 1
      assert_select 'div.list_item_title a[href=?]', sop_path(sops(:sop_with_private_policy_and_custom_sharing)), count: 0
      assert_select 'div.list_item_actions a[href=?]', download_sop_path(sops(:sop_with_private_policy_and_custom_sharing)), count: 0

      assert_select 'div.list_item_title a[href=?]', data_file_path(data_files(:downloadable_data_file)), text: 'Downloadable Only', count: 1
      assert_select 'div.list_item_actions a[href=?]', download_data_file_path(data_files(:downloadable_data_file)), count: 1
      assert_select 'div.list_item_title a[href=?]', data_file_path(data_files(:private_data_file)), count: 0
      assert_select 'div.list_item_actions a[href=?]', download_data_file_path(data_files(:private_data_file)), count: 0
    end
  end

  test "associated assets aren't lost on failed validation in create" do
    sop = sops(:sop_with_all_sysmo_users_policy)
    model = models(:model_with_links_in_description)
    datafile = data_files(:downloadable_data_file)
    rel = RelationshipType.first

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count', 'Should not have added assay because the title is blank') do
        assert_no_difference('AssayAsset.count', 'Should not have added assay assets because the assay validation failed') do
          # title is blank, so should fail validation
          post :create, params: { assay: {
            title: '',
            technology_type_uri: 'http://some-uri#tech',
            assay_type_uri: 'http://some-uri#assay',
            study_id: studies(:metabolomics_study).id,
            assay_class_id: assay_classes(:modelling_assay_class).id,
            sop_ids: ["#{sop.id}"],
            model_ids: ["#{model.id}"],
            data_files_attributes: [{ asset_id: datafile.id, relationship_type_id: rel.id }]
          }, policy_attributes: valid_sharing }
        end
      end
    end

    sop_json = JSON.parse(select_node_contents('#add_sops_form [data-role="seek-existing-associations"]'))
    assert_equal 1, sop_json.length
    assert_equal sop.title, sop_json[0]['title']
    assert_equal sop.id, sop_json[0]['id']

    model_json = JSON.parse(select_node_contents('#add_models_form [data-role="seek-existing-associations"]'))
    assert_equal 1, model_json.length
    assert_equal model.title, model_json[0]['title']
    assert_equal model.id, model_json[0]['id']

    df_json = JSON.parse(select_node_contents('#data_file_to_list script'))
    assert_equal 1, df_json.length
    assert_equal datafile.title, df_json[0]['title']
    assert_equal datafile.id, df_json[0]['id']
    assert_equal rel.id, df_json[0]['relationship_type']['value']
  end

  test 'should create with associated model sop data file and publication' do
    person = FactoryBot.create :person
    login_as(person.user)
    sop = FactoryBot.create :sop, policy: FactoryBot.create(:public_policy), contributor: person
    model = FactoryBot.create :model, policy: FactoryBot.create(:public_policy), contributor: person
    df = FactoryBot.create :data_file, policy: FactoryBot.create(:public_policy), contributor: person
    pub = FactoryBot.create :publication, contributor: person
    study = FactoryBot.create :study, policy: FactoryBot.create(:public_policy), contributor: person
    rel = RelationshipType.first

    assert_difference('ActivityLog.count') do
      assert_difference('Assay.count') do
        assert_difference('AssayAsset.count', 3) do
          assert_difference('Relationship.count') do
            post :create, params: { assay: {
                title: 'fish',
                study_id: study.id,
                assay_class_id: assay_classes(:modelling_assay_class).id,
                sop_ids: ["#{sop.id}"],
                model_ids: ["#{model.id}"],
                data_files_attributes: [{ asset_id: df.id, relationship_type_id: rel.id }],
                publication_ids: ["#{pub.id}"]
            }, policy_attributes: valid_sharing } # default policy is nil in VLN
          end
        end
      end
    end

    assert_not_nil assigns(:assay)
    assay = assigns(:assay)
    assay.reload # necessary to pickup the relationships for publications
    assert_equal [sop], assay.sops
    assert_equal [df], assay.data_files
    assert_equal [model], assay.models
    assert_equal [pub], assay.publications
  end

  test "associated assets aren't lost on failed validation on update" do
    login_as(:model_owner)
    assay = assays(:assay_with_links_in_description)

    # remove any existing associated assets
    assay.assets.clear
    assay.save!
    assay.reload
    assert assay.sops.empty?
    assert assay.models.empty?
    assert assay.data_files.empty?

    sop = sops(:sop_with_all_sysmo_users_policy)
    assert sop.can_view?
    model = models(:model_with_links_in_description)
    assert model.can_view?
    datafile = data_files(:downloadable_data_file)
    assert datafile.can_view?

    rel = RelationshipType.first

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('AssayAsset.count', 'Should not have added assay assets because the assay validation failed') do
        assert_no_difference('Assay.count', 'Should not have added assay because the title is blank') do
          # title is blank, so should fail validation
          put :update, params: { id: assay, assay: { title: '',
                                           assay_class_id: assay_classes(:modelling_assay_class).id,
                                           sop_ids: ["#{sop.id}"],
                                           model_ids: ["#{model.id}"],
                                           data_files_attributes: [{ asset_id: datafile.id, relationship_type_id: rel.id }]
          } }
        end
      end
    end
    sop_json = JSON.parse(select_node_contents('#add_sops_form [data-role="seek-existing-associations"]'))
    assert_equal 1, sop_json.length
    assert_equal sop.title, sop_json[0]['title']
    assert_equal sop.id, sop_json[0]['id']

    model_json = JSON.parse(select_node_contents('#add_models_form [data-role="seek-existing-associations"]'))
    assert_equal 1, model_json.length
    assert_equal model.title, model_json[0]['title']
    assert_equal model.id, model_json[0]['id']

    df_json = JSON.parse(select_node_contents('#data_file_to_list script'))
    assert_equal 1, df_json.length
    assert_equal datafile.title, df_json[0]['title']
    assert_equal datafile.id, df_json[0]['id']
    assert_equal rel.id, df_json[0]['relationship_type']['value']
  end

  def check_fixtures_for_authorization_of_sops_and_datafiles_links
    user = users(:model_owner)
    assay = assays(:assay_with_public_and_private_sops_and_datafiles)
    assert_equal 4, assay.assets.size
    assert_equal 2, assay.sops.size
    assert_equal 2, assay.data_files.size
    assert assay.sops.include?(sops(:sop_with_fully_public_policy))
    assert assay.sops.include?(sops(:sop_with_private_policy_and_custom_sharing))
    assert assay.data_files.include?(data_files(:downloadable_data_file))
    assert assay.data_files.include?(data_files(:private_data_file))

    assert sops(:sop_with_fully_public_policy).can_view? user
    assert !sops(:sop_with_private_policy_and_custom_sharing).can_view?(user)
    assert data_files(:downloadable_data_file).can_view?(user)
    assert !data_files(:private_data_file).can_view?(user)
  end

  test 'filtering by study' do
    study = studies(:metabolomics_study)
    get :index, params: { filter: { study: study.id } }
    assert_response :success
  end

  test 'filtering by investigation' do
    inv = investigations(:metabolomics_investigation)
    get :index, params: { filter: { investigation: inv.id } }
    assert_response :success
  end

  test 'filtering by project' do
    project = projects(:sysmo_project)
    get :index, params: { filter: { project: project.id } }
    assert_response :success
  end

  test 'filtering by person' do
    person = people(:person_for_model_owner)
    get :index, params: { filter: { contributor: person.id }, page: 'all' }
    assert_response :success
    a = assays(:metabolomics_assay)
    a2 = assays(:modelling_assay_with_data_and_relationship)
    assert_select 'div.list_items_container' do
      assert_select 'a', text: a.title, count: 1
      assert_select 'a', text: a2.title, count: 0
    end
  end

  test 'edit assay with selected projects scope policy' do
    person = User.current_user.person
    proj = person.projects.first
    investigation = FactoryBot.create(:investigation, projects: [proj], contributor:person)
    assay = FactoryBot.create(:assay, contributor: person,
                            study: FactoryBot.create(:study, investigation: investigation,contributor:person),
                            policy: FactoryBot.create(:policy,
                                            access_type: Policy::NO_ACCESS,
                                            permissions: [FactoryBot.create(:permission, contributor: proj, access_type: Policy::EDITING)]))
    get :edit, params: { id: assay.id }
    assert_response :success
  end

  test "should create sharing permissions 'with your project and with all SysMO members'" do

    study = FactoryBot.create(:study,contributor:User.current_user.person)

    a = { title: 'test',
          study_id: study.id,
          assay_class_id: assay_classes(:experimental_assay_class).id }

    assert_difference('ActivityLog.count') do
      assert_difference('Assay.count') do
        post :create, params: { assay: a, policy_attributes: { access_type: Policy::VISIBLE,
                                           permissions_attributes: project_permissions(study.projects, Policy::ACCESSIBLE) } }
      end
    end

    assay = assigns(:assay)
    assert_redirected_to assay_path(assay)
    assert_equal Policy::VISIBLE, assay.policy.access_type
    assert_equal 1, assay.policy.permissions.count

    assay.policy.permissions.each do |permission|
      assert_equal permission.contributor_type, 'Project'
      assert assay.study.investigation.project_ids.include?(permission.contributor_id)
      assert_equal permission.policy_id, assay.policy_id
      assert_equal permission.access_type, Policy::ACCESSIBLE
    end
  end

  test "should update sharing permissions 'with your project and with all SysMO members'" do
    person = FactoryBot.create(:person)
    person.add_to_project_and_institution(FactoryBot.create(:project),FactoryBot.create(:institution))
    login_as person.user

    inv = FactoryBot.create(:investigation, projects: person.projects,contributor: person)
    study = FactoryBot.create(:study, investigation: inv, contributor: person)
    assay = FactoryBot.create(:assay,
                    policy: FactoryBot.create(:private_policy),
                    contributor: person,
                    study: study)

    assert_equal 2, study.projects.count
    assert assay.can_manage?
    assert_equal Policy::NO_ACCESS, assay.policy.access_type
    assert assay.policy.permissions.empty?

    assert_difference('ActivityLog.count') do
      put :update, params: { id: assay, assay: { title: assay.title }, policy_attributes: { access_type: Policy::ACCESSIBLE,
                                        permissions_attributes: project_permissions(study.projects, Policy::EDITING) } }
    end

    assay.reload
    assert_redirected_to assay_path(assay)
    assert_equal Policy::ACCESSIBLE, assay.policy.access_type
    assert_equal 2, assay.policy.permissions.count

    assay.policy.permissions.each do |update_permission|
      assert_equal update_permission.contributor_type, 'Project'
      assert assay.projects.map(&:id).include?(update_permission.contributor_id)
      assert_equal update_permission.policy_id, assay.policy_id
      assert_equal update_permission.access_type, Policy::EDITING
    end
  end

  test 'should have associated datafiles, models, on modelling assay show page' do
    df = FactoryBot.create(:data_file, contributor: User.current_user.person)
    model = FactoryBot.create(:model, contributor: User.current_user.person)
    investigation = FactoryBot.create(:investigation, contributor:User.current_user.person)
    assay = FactoryBot.create(:assay, contributor: User.current_user.person,
                            study: FactoryBot.create(:study, investigation: investigation, contributor:User.current_user.person))
    assay.data_files << df
    assay.models << model
    assert assay.save
    assert assay.is_modelling?

    get :show, params: { id: assay }
    assert_response :success
    assert_select 'a[href=?]', data_file_path(df), text: df.title
    assert_select 'a[href=?]', model_path(model), text: model.title
  end

  test 'should have associated datafiles, models and sops on assay index page for modelling assays' do
    Assay.delete_all
    df = FactoryBot.create(:data_file, contributor: User.current_user.person)
    model = FactoryBot.create(:model, contributor: User.current_user.person)
    sop = FactoryBot.create(:sop, contributor: User.current_user.person)
    investigation = FactoryBot.create(:investigation, contributor:User.current_user.person)
    assay = FactoryBot.create(:modelling_assay, contributor: User.current_user.person,
                    study: FactoryBot.create(:study, investigation: investigation, contributor:User.current_user.person))
    assay.data_files << df
    assay.models << model
    assay.sops << sop
    assert assay.save
    assert assay.is_modelling?

    get :index
    assert_response :success
    assert_select 'a[href=?]', data_file_path(df), text: df.title
    assert_select 'a[href=?]', model_path(model), text: model.title
    assert_select 'a[href=?]', sop_path(sop), text: sop.title
  end

  test 'preview assay with associated hidden items' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy), contributor:User.current_user.person)
    private_df = FactoryBot.create(:data_file, policy: FactoryBot.create(:private_policy),contributor:User.current_user.person)
    assay.data_files << private_df
    assay.save!
    login_as FactoryBot.create(:user)
    get :preview, xhr: true, params: { id: assay.id }
    assert_response :success
  end

  test 'should not show private data or model title on modelling analysis summary' do
    person = User.current_user.person
    df = FactoryBot.create(:data_file, title: 'private data file', policy: FactoryBot.create(:private_policy),contributor: person)
    df2 = FactoryBot.create(:data_file, title: 'public data file', policy: FactoryBot.create(:public_policy),contributor: person)
    model = FactoryBot.create(:model, title: 'private model', policy: FactoryBot.create(:private_policy),contributor: person)
    model2 = FactoryBot.create(:model, title: 'public model', policy: FactoryBot.create(:public_policy),contributor: person)
    assay = FactoryBot.create(:modelling_assay, policy: FactoryBot.create(:public_policy),contributor: person)

    assay.data_files << df
    assay.data_files << df2
    assay.models << model
    assay.models << model2

    assay.save!

    login_as FactoryBot.create(:person)

    get :show, params: { id: assay.id }
    assert_response :success
    assert_select 'div.data_model_relationship' do
      assert_select 'ul.related_models' do
        assert_select 'li a[href=?]', model_path(model2), text: /#{model2.title}/, count: 1
        assert_select 'li a[href=?]', model_path(model), text: /#{model.title}/, count: 0
        assert_select 'li', text: /Hidden/, count: 1
      end
      assert_select 'ul.related_data_files' do
        assert_select 'li a[href=?]', data_file_path(df2), text: /#{df2.title}/, count: 1
        assert_select 'li a[href=?]', data_file_path(df), text: /#{df.title}/, count: 0
        assert_select 'li', text: /Hidden/, count: 1
      end
    end
  end

  test 'should not show investigation and study title if they are hidden on assay show page' do
    investigation = FactoryBot.create(:investigation,
                            policy: FactoryBot.create(:private_policy),
                            contributor: User.current_user.person)
    study = FactoryBot.create(:study,
                    policy: FactoryBot.create(:private_policy),
                    contributor: User.current_user.person,
                    investigation: investigation)
    assay = FactoryBot.create(:assay,
                    policy: FactoryBot.create(:public_policy),
                    study: study,
                    contributor: User.current_user.person)

    logout
    get :show, params: { id: assay }
    assert_response :success
    assert_select 'p#investigation' do
      assert_select 'span.none_text', text: /hidden item/, count: 1
    end
    assert_select 'p#study' do
      assert_select 'span.none_text', text: /hidden item/, count: 1
    end
  end

  test 'edit should include tags element' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    get :edit, params: { id: assay.id }
    assert_response :success

    assert_select 'div.panel-heading', text: /Tags/, count: 1
    assert_select 'select#tag_list', count: 1
  end

  test 'new should include tags element' do
    get :new, params: { class: 'EXP' }
    assert_response :success
    assert_select 'div.panel-heading', text: /Tags/, count: 1
    assert_select 'select#tag_list', count: 1
  end

  test 'edit should include not include tags element when tags disabled' do
    with_config_value :tagging_enabled, false do
      assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
      get :edit, params: { id: assay.id }
      assert_response :success

      assert_select 'div.panel-heading', text: /Tags/, count: 0
      assert_select 'select#tag_list', count: 0
    end
  end

  test 'new should not include tags element when tags disabled' do
    with_config_value :tagging_enabled, false do
      get :new, params: { class: 'EXP' }
      assert_response :success
      assert_select 'div.panel-heading', text: /Tags/, count: 0
      assert_select 'select#tag_list', count: 0
    end
  end

  test 'new object based on existing one' do
    person = User.current_user.person
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy), contributor:person)
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy), investigation: investigation, contributor:person)
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy), title: 'the assay', study: study, contributor:person)
    assert assay.can_view?
    assert assay.study.can_edit?
    get :new_object_based_on_existing_one, params: { id: assay.id }
    assert_response :success
    assert_select '#assay_title[value=?]', 'the assay'
    assert_select "select#assay_study_id option[selected][value='#{assay.study.id}']",count: 1
  end

  test 'new object based on existing one when unauthorised to view' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:private_policy), title: 'the assay')
    refute assay.can_view?
    get :new_object_based_on_existing_one, params: { id: assay.id }
    assert_response :forbidden
  end

  test 'new object based on existing one when can view but not logged in' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    logout
    assert assay.can_view?
    get :new_object_based_on_existing_one, params: { id: assay.id }
    assert_redirected_to assay
    refute_nil flash[:error]
  end

  test 'should show experimental assay types for new experimental assay' do
    get :new, params: { class: 'EXP' }
    assert_response :success
    assert_select 'label', text: /assay type/i
    assert_select 'select#assay_assay_type_uri' do
      assert_select 'option[value=?]', 'http://jermontology.org/ontology/JERMOntology#Fluxomics', text: /Fluxomics/i
      assert_select 'option[value=?]', 'http://jermontology.org/ontology/JERMOntology#Cell_cycle', text: /Cell cycle/i, count: 0
    end
  end

  test 'should show modelling assay types for new modelling assay' do
    get :new, params: { class: 'MODEL' }
    assert_response :success
    assert_select 'label', text: /Biological problem addressed/i
    assert_select 'select#assay_assay_type_uri' do
      assert_select 'option[value=?]', 'http://jermontology.org/ontology/JERMOntology#Cell_cycle', text: /Cell cycle/i
      assert_select 'option[value=?]', 'http://jermontology.org/ontology/JERMOntology#Fluxomics', text: /Fluxomics/i, count: 0
    end
  end

  test 'should show experimental assay types when editing experimental assay' do
    a = FactoryBot.create(:experimental_assay, contributor: User.current_user.person)
    get :edit, params: { id: a.id }
    assert_response :success
    assert_select 'label', text: /assay type/i
    assert_select 'select#assay_assay_type_uri' do
      assert_select 'option[value=?]', 'http://jermontology.org/ontology/JERMOntology#Fluxomics', text: /Fluxomics/i
      assert_select 'option[value=?]', 'http://jermontology.org/ontology/JERMOntology#Cell_cycle', text: /Cell cycle/i, count: 0
    end
  end

  test 'should show modelling assay types when editing modelling assay' do
    a = FactoryBot.create(:modelling_assay, contributor: User.current_user.person)
    get :edit, params: { id: a.id }
    assert_response :success
    assert_select 'label', text: /Biological problem addressed/i
    assert_select 'select#assay_assay_type_uri' do
      assert_select 'option[value=?]', 'http://jermontology.org/ontology/JERMOntology#Cell_cycle', text: /Cell cycle/i
      assert_select 'option[value=?]', 'http://jermontology.org/ontology/JERMOntology#Fluxomics', text: /Fluxomics/i, count: 0
    end
  end

  test 'assays filtered by investigation via nested routing' do
    assert_routing 'investigations/1/assays', controller: 'assays', action: 'index', investigation_id: '1'
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    inv = assay.study.investigation
    assay2 = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    refute_nil(inv)
    refute_equal assay.study.investigation, assay2.study.investigation
    get :index, params: { investigation_id: inv.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', assay_path(assay), text: assay.title
      assert_select 'a[href=?]', assay_path(assay2), text: assay2.title, count: 0
    end
  end

  test 'assays filtered by study via nested routing' do
    assert_routing 'studies/1/assays', controller: 'assays', action: 'index', study_id: '1'
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    study = assay.study
    assay2 = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))

    refute_equal assay.study, assay2.study
    get :index, params: { study_id: study.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', assay_path(assay), text: assay.title
      assert_select 'a[href=?]', assay_path(assay2), text: assay2.title, count: 0
    end
  end

  test 'filtered assays for non existent study' do
    FactoryBot.create :assay # needs an assay to be sure that the problem being fixed is triggered
    study_id = 999
    assert_nil Study.find_by_id(study_id)
    get :index, params: { study_id: study_id }
    assert_response :not_found
  end

  test "logged out user can't see new" do
    logout
    get :new
    assert_redirected_to assays_path
  end

  test 'assays filtered by strain through nested route' do
    assert_routing 'strains/3/assays', controller: 'assays', action: 'index', strain_id: '3'
    ao1 = FactoryBot.create(:assay_organism, assay: FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy)))
    ao2 = FactoryBot.create(:assay_organism, assay: FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy)))
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

    get :index, params: { strain_id: strain1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', assay_path(assay1), text: assay1.title
      assert_select 'a[href=?]', assay_path(assay2), text: assay2.title, count: 0
    end
  end

  test 'should add creators' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    creator = FactoryBot.create(:person)
    assert assay.creators.empty?

    put :update, params: { id: assay.id, assay: { title: assay.title, creator_ids: [creator.id] } }
    assert_redirected_to assay_path(assay)

    assert assay.creators.include?(creator)
  end

  test 'should show creators' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    creator = FactoryBot.create(:person)
    assay.creators = [creator]
    assay.save
    assay.reload
    assert assay.creators.include?(creator)

    get :show, params: { id: assay.id }
    assert_response :success
    assert_select 'li.author-list-item a[href=?]', "/people/#{creator.id}"
  end

  test 'should show other creators' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    other_creators = 'john smith, jane smith'
    assay.other_creators = other_creators
    assay.save
    assay.reload

    get :show, params: { id: assay.id }
    assert_response :success
    assert_select '#author-box .additional-credit', text: 'john smith, jane smith', count: 1
  end

  test 'programme assays through nested routing' do
    assert_routing 'programmes/2/assays', controller: 'assays', action: 'index', programme_id: '2'
    programme = FactoryBot.create(:programme)
    person = FactoryBot.create(:person,project:programme.projects.first)
    other_person = FactoryBot.create(:person)
    investigation = FactoryBot.create(:investigation, projects: programme.projects, policy: FactoryBot.create(:public_policy),contributor:person)
    investigation2 = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy),contributor:other_person)
    study = FactoryBot.create(:study, investigation: investigation, policy: FactoryBot.create(:public_policy),contributor:person)
    study2 = FactoryBot.create(:study, investigation: investigation2, policy: FactoryBot.create(:public_policy),contributor:other_person)
    assay = FactoryBot.create(:assay, study: study, policy: FactoryBot.create(:public_policy),contributor:person)
    assay2 = FactoryBot.create(:assay, study: study2, policy: FactoryBot.create(:public_policy),contributor:other_person)

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', assay_path(assay), text: assay.title
      assert_select 'a[href=?]', assay_path(assay2), text: assay2.title, count: 0
    end
  end

  test "document assays through nested routing" do
    assert_routing 'documents/2/assays', controller: 'assays', action: 'index', document_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor:person)
    assay2 = FactoryBot.create(:assay, contributor:person)
    document = FactoryBot.create(:document,assays:[assay],contributor:person)

    get :index, params: { document_id: document.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', assay_path(assay), text: assay.title
      assert_select 'a[href=?]', assay_path(assay2), text: assay2.title, count: 0
    end
  end

  test 'should show NeLS button for NeLS-enabled project' do
    person = FactoryBot.create(:person)
    login_as(person.user)
    project = person.projects.first
    project.settings.set('nels_enabled', true)
    inv = FactoryBot.create(:investigation, projects: [project], contributor:person)
    study = FactoryBot.create(:study, investigation: inv, contributor:person)
    assay = FactoryBot.create(:assay, contributor: person, study: study)

    get :show, params: { id: assay }

    assert_response :success
    assert_select 'a[href=?]', assay_nels_path(assay.id), count: 1
  end

  test 'should not show NeLS button if NeLS integration disabled' do
    person = FactoryBot.create(:person)
    login_as(person.user)
    project = person.projects.first
    project.settings.set('nels_enabled', true)
    inv = FactoryBot.create(:investigation, projects: [project],contributor: person)
    study = FactoryBot.create(:study, investigation: inv,contributor: person)
    assay = FactoryBot.create(:assay, contributor: person, study: study)

    with_config_value(:nels_enabled, false) do
      get :show, params: { id: assay }
    end

    assert_response :success
    assert_select 'a[href=?]', assay_nels_path(assay.id), count: 0
  end

  test 'should not show NeLS button for non-NeLS' do
    person = FactoryBot.create(:person)
    login_as(person.user)
    project = person.projects.first
    inv =  FactoryBot.create(:investigation, projects: [project], contributor: person)
    study = FactoryBot.create(:study,investigation:inv,contributor: person )
    assay = FactoryBot.create(:assay, contributor: person, study: study)

    get :show, params: { id: assay }

    assert_response :success
    assert_select 'a[href=?]', assay_nels_path(assay.id), count: 0
  end

  test 'should not show NeLS button for NeLS-enabled project to non-NeLS project member' do
    nels_person = FactoryBot.create(:person)
    non_nels_person = FactoryBot.create(:person)
    login_as(non_nels_person)
    nels_project = nels_person.projects.first
    non_nels_project = non_nels_person.projects.first

    assert_empty nels_person.projects & non_nels_person.projects

    inv = FactoryBot.create(:investigation, project_ids: [nels_project.id],contributor:nels_person)
    study = FactoryBot.create(:study, investigation: inv, contributor:nels_person)
    assay = FactoryBot.create(:assay, contributor: nels_person, study: study, policy: FactoryBot.create(:policy, permissions: [
        FactoryBot.create(:permission, contributor: nels_project, access_type: Policy::MANAGING),
        FactoryBot.create(:permission, contributor: non_nels_project, access_type: Policy::MANAGING)]))

    get :show, params: { id: assay }

    assert_response :success
    assert_select 'a[href=?]', edit_assay_path, count: 1 # Can manage
    assert_select 'a[href=?]', assay_nels_path(assay.id), count: 0 # But not browse NeLS
  end

  test 'can delete an assay with subscriptions' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    p = FactoryBot.create(:person)
    FactoryBot.create(:subscription, person: assay.contributor, subscribable: assay)
    FactoryBot.create(:subscription, person: p, subscribable: assay)

    login_as(assay.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Assay.count', -1) do
        delete :destroy, params: { id: assay.id }
      end
    end

    assert_redirected_to assays_path
  end

  test 'should associate document' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor: person, created_at: 1.day.ago, updated_at: 1.day.ago)
    document = FactoryBot.create(:document, contributor: person)
    timestamp = assay.updated_at

    assert_not_includes assay.documents, document

    assert_difference('AssayAsset.count', 1) do
      put :update, params: { id: assay, assay: { title: assay.title, document_ids: [document.id] } }
    end

    assert_redirected_to assay_path(assay)
    assert_includes assigns(:assay).documents, document
    assert_not_equal timestamp, assigns(:assay).updated_at
  end

  test 'should not associate private document' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor: person)
    document = FactoryBot.create(:document, policy: FactoryBot.create(:private_policy))

    assert_not_includes assay.documents, document
    refute document.can_view?(person.user)

    assert_no_difference('AssayAsset.count') do
      put :update, params: { id: assay, assay: { title: assay.title, document_ids: [document.id] } }
    end

    assert_redirected_to assay_path(assay)
    assert_not_includes assigns(:assay).documents, document
  end

  test 'should disassociate document' do
    person = FactoryBot.create(:person)
    login_as(person)
    document = FactoryBot.create(:document, contributor: person)
    assay = FactoryBot.create(:assay, contributor: person, documents: [document])

    assert_includes assay.documents, document

    assert_difference('AssayAsset.count', -1) do
      put :update, params: { id: assay, assay: { title: assay.title, document_ids: [''] } }
    end

    assert_redirected_to assay_path(assay)
    assert_not_includes assigns(:assay).documents, document
  end

  test 'should associate sop' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor: person, created_at: 1.day.ago, updated_at: 1.day.ago)
    sop = FactoryBot.create(:sop, contributor: person)
    timestamp = assay.updated_at

    assert_not_includes assay.sops, sop

    assert_difference('AssayAsset.count', 1) do
      put :update, params: { id: assay, assay: { title: assay.title, sop_ids: [sop.id] } }
    end

    assert_redirected_to assay_path(assay)
    assert_includes assigns(:assay).sops, sop
    assert_not_equal timestamp, assigns(:assay).updated_at
  end

  test 'should not associate private sop' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor: person)
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:private_policy))

    assert_not_includes assay.sops, sop
    refute sop.can_view?(person.user)

    assert_no_difference('AssayAsset.count') do
      put :update, params: { id: assay, assay: { title: assay.title, sop_ids: [sop.id] } }
    end

    assert_redirected_to assay_path(assay)
    assert_not_includes assigns(:assay).sops, sop
  end

  test 'should disassociate sop' do
    person = FactoryBot.create(:person)
    login_as(person)
    sop = FactoryBot.create(:sop, contributor: person)
    assay = FactoryBot.create(:assay, contributor: person, sops: [sop])

    assert_includes assay.sops, sop

    assert_difference('AssayAsset.count', -1) do
      put :update, params: { id: assay, assay: { title: assay.title, sop_ids: [''] } }
    end

    assert_redirected_to assay_path(assay)
    assert_not_includes assigns(:assay).sops, sop
  end

  test 'should associate model' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor: person, created_at: 1.day.ago, updated_at: 1.day.ago)
    model = FactoryBot.create(:model, contributor: person)
    timestamp = assay.updated_at

    assert_not_includes assay.models, model

    assert_difference('AssayAsset.count', 1) do
      put :update, params: { id: assay, assay: { title: assay.title, model_ids: [model.id] } }
    end

    assert_redirected_to assay_path(assay)
    assert_includes assigns(:assay).models, model
    assert_not_equal timestamp, assigns(:assay).updated_at
  end

  test 'should not associate private model' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor: person)
    model = FactoryBot.create(:model, policy: FactoryBot.create(:private_policy))

    assert_not_includes assay.models, model
    refute model.can_view?(person.user)

    assert_no_difference('AssayAsset.count') do
      put :update, params: { id: assay, assay: { title: assay.title, model_ids: [model.id] } }
    end

    assert_redirected_to assay_path(assay)
    assert_not_includes assigns(:assay).models, model
  end

  test 'should disassociate model' do
    person = FactoryBot.create(:person)
    login_as(person)
    model = FactoryBot.create(:model, contributor: person)
    assay = FactoryBot.create(:assay, contributor: person, models: [model])

    assert_includes assay.models, model

    assert_difference('AssayAsset.count', -1) do
      put :update, params: { id: assay, assay: { title: assay.title, model_ids: [''] } }
    end

    assert_redirected_to assay_path(assay)
    assert_not_includes assigns(:assay).models, model
  end

  test 'cannot create with link to study in another project' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    login_as(person)
    investigation = FactoryBot.create(:investigation,contributor:another_person,projects:another_person.projects)
    study = FactoryBot.create(:study, investigation:investigation,policy:FactoryBot.create(:publicly_viewable_policy), contributor:another_person )
    assert study.can_view?
    assert_empty person.projects & study.projects
    assert_no_difference('Assay.count') do
      post :create, params: { assay: { title: 'test', study_id: study.id, assay_class_id: AssayClass.experimental.id }, policy_attributes: valid_sharing }
    end
    assert_response :unprocessable_entity
  end

  test 'cannot create with hidden study in same project' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!
    login_as(person)
    investigation = FactoryBot.create(:investigation,contributor:another_person,projects:person.projects)
    study = FactoryBot.create(:study, investigation:investigation,policy:FactoryBot.create(:private_policy), contributor:another_person )
    refute study.can_view?
    refute_empty person.projects & study.projects

    assert_no_difference('Assay.count') do
      post :create, params: { assay: { title: 'test', study_id: study.id, assay_class_id: AssayClass.experimental.id }, policy_attributes: valid_sharing }
    end
    assert_response :unprocessable_entity
  end

  test 'cannot update with link to study in another project' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    login_as(person)
    investigation = FactoryBot.create(:investigation,contributor:another_person,projects:another_person.projects)
    study = FactoryBot.create(:study,contributor:another_person,investigation:investigation,policy:FactoryBot.create(:publicly_viewable_policy))
    assay = FactoryBot.create(:assay,contributor:person)

    assert study.can_view?
    assert_empty person.projects & study.projects

    refute_equal study,assay.study

    put :update, params: { id:assay.id, assay:{study_id:study.id} }

    assert_response :unprocessable_entity
    assay.reload
    refute_equal study,assay.study
  end

  test 'cannot update with link to hidden study in same project' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!
    login_as(person)
    investigation = FactoryBot.create(:investigation,contributor:another_person,projects:person.projects)
    study = FactoryBot.create(:study,contributor:another_person,investigation:investigation,policy:FactoryBot.create(:private_policy))
    assay = FactoryBot.create(:assay,contributor:person)

    refute study.can_view?
    refute_empty person.projects & study.projects
    refute_equal study,assay.study

    put :update, params: { id:assay.id, assay:{study_id:study.id} }

    assert_response :unprocessable_entity
    assay.reload
    refute_equal study,assay.study
  end

  test 'cannot update and link to none visible SOP' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay,contributor:person)
    assert assay.can_edit?

    good_sop = FactoryBot.create(:sop,policy:FactoryBot.create(:publicly_viewable_policy))
    bad_sop = FactoryBot.create(:sop,policy:FactoryBot.create(:private_policy))
    assert good_sop.can_view?
    refute bad_sop.can_view?

    assert_no_difference('AssayAsset.count') do
      put :update, params: { id: assay, assay: { title: assay.title, sop_ids: [bad_sop.id] } }
    end
    #FIXME: it currently ignores the bad asset, but ideally should respond with an error
    #assert_response :unprocessable_entity
    assay.reload
    assert_empty assay.sops

    assert_difference('AssayAsset.count') do
      put :update, params: { id: assay, assay: { title: assay.title, sop_ids: [good_sop.id] } }
    end
    assay.reload
    assert_equal [good_sop],assay.sops

  end

  test 'cannot create and link to none visible SOP' do
    person = FactoryBot.create(:person)
    login_as(person)

    investigation = FactoryBot.create(:investigation,contributor:person)
    study = FactoryBot.create(:study, investigation:investigation,policy:FactoryBot.create(:publicly_viewable_policy), contributor:person)


    good_sop = FactoryBot.create(:sop,policy:FactoryBot.create(:publicly_viewable_policy))
    bad_sop = FactoryBot.create(:sop,policy:FactoryBot.create(:private_policy))
    assert good_sop.can_view?
    refute bad_sop.can_view?

    assert_no_difference('AssayAsset.count') do
      post :create, params: { assay: { title: 'testing',
                             assay_class_id: AssayClass.experimental.id,
                             study_id: study.id,
                             sop_ids: [bad_sop.id] }, policy_attributes: valid_sharing }
    end
    #FIXME: it currently ignores the bad asset, but ideally should respond with an error
    #assert_response :unprocessable_entity
    assert_empty assigns(:assay).sops


    assert_difference('AssayAsset.count') do
      post :create, params: { assay: { title: 'testing',
                             assay_class_id: AssayClass.experimental.id,
                             study_id: study.id,
                             sop_ids: [good_sop.id] }, policy_attributes: valid_sharing }
    end
    assay = assigns(:assay)
    assert_equal [good_sop],assay.sops

  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('assay')
  end

  test 'can access manage page with manage rights' do
    person = FactoryBot.create(:person)
    assay = FactoryBot.create(:assay, contributor:person)
    login_as(person)
    assert assay.can_manage?
    get :manage, params: {id: assay}
    assert_response :success

    #shouldn't be a projects block
    assert_select 'div#add_projects_form', count:0

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    #no sharing link, not for Investigation, Study and Assay
    assert_select 'div#temporary_links', count:0

    assert_select 'div#author-form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = FactoryBot.create(:person)
    assay = FactoryBot.create(:assay, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert assay.can_edit?
    refute assay.can_manage?
    get :manage, params: {id:assay}
    assert_redirected_to assay
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj1)
    other_person = FactoryBot.create(:person)

    other_creator = FactoryBot.create(:person,project:proj1)

    assay = FactoryBot.create(:assay, contributor:person, policy:FactoryBot.create(:private_policy))

    login_as(person)
    assert assay.can_manage?

    patch :manage_update, params: {id: assay,
                                   assay: {
                                       creator_ids: [other_creator.id],
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to assay

    assay.reload
    assert_equal [other_creator],assay.creators
    assert_equal Policy::VISIBLE,assay.policy.access_type
    assert_equal 1,assay.policy.permissions.count
    assert_equal other_person,assay.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,assay.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=FactoryBot.create(:project)

    person = FactoryBot.create(:person, project:proj1)


    other_person = FactoryBot.create(:person)

    other_creator = FactoryBot.create(:person,project:proj1)


    assay = FactoryBot.create(:assay, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute assay.can_manage?
    assert assay.can_edit?

    assert_empty assay.creators

    patch :manage_update, params: {id: assay,
                                   assay: {
                                       creator_ids: [other_creator.id],
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    assay.reload
    assert_equal Policy::PRIVATE,assay.policy.access_type
    assert_equal 1,assay.policy.permissions.count
    assert_equal person,assay.policy.permissions.first.contributor
    assert_equal Policy::EDITING,assay.policy.permissions.first.access_type

  end

  test 'should create with discussion link' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay_type = FactoryBot.create(:suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics', label: 'fish')
    tech_type = FactoryBot.create(:suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography', label: 'carrot')
    assert_difference('AssetLink.discussion.count') do
    assert_difference('Assay.count') do
      post :create, params: { assay: { title: 'test',
                                       technology_type_uri: tech_type.uri,
                                       assay_type_uri: assay_type.uri,
                                       study_id: FactoryBot.create(:study,contributor:User.current_user.person).id,
                                       assay_class_id: FactoryBot.create(:experimental_assay_class).id,
                                       discussion_links_attributes: [{url: "http://www.slack.com/"}]},
                              policy_attributes: valid_sharing }
    end
    end
    assay = assigns(:assay)
    assert_equal 'http://www.slack.com/', assay.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, assay.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    disc_link = FactoryBot.create(:discussion_link)
    assay = FactoryBot.create(:assay, contributor: User.current_user.person)
    assay.discussion_links = [disc_link]
    get :show, params: { id: assay }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update node with discussion link' do
    person = FactoryBot.create(:person)
    assay = FactoryBot.create(:assay, contributor: person)
    login_as(person)
    assert_nil assay.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: assay.id, assay: { discussion_links_attributes:[{url: "http://www.slack.com/"}] } }
      end
    end
    assert_redirected_to assay_path(assigns(:assay))
    assert_equal 'http://www.slack.com/', assay.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = FactoryBot.create(:person)
    login_as(person)
    asset_link = FactoryBot.create(:discussion_link)
    assay = FactoryBot.create(:assay, contributor: person)
    assay.discussion_links = [asset_link]
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: assay.id, assay: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to assay_path(assay = assigns(:assay))
    assert_empty assay.discussion_links
  end

  test 'add new honours enabled setting' do
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor: person)

    with_config_value(:documents_enabled, true) do
      get :show, params: { id: assay.id }
      assert_select 'ul#item-admin-menu li a',text: /add new document/i, count:1
    end

    with_config_value(:documents_enabled, false) do
      get :show, params: { id: assay.id }
      assert_select 'ul#item-admin-menu li a',text: /add new document/i, count:0
    end
  end

  test 'last updated by - content' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    a = FactoryBot.create :assay, policy: FactoryBot.create(:public_policy), created_at: 15.minute.ago, contributor: person1
    FactoryBot.create :activity_log, activity_loggable: a, action: 'create', created_at: 15.minute.ago, culprit: person1
    login_as(person1)
    get :show, params: { id: a.id }
    assert_response :success
    assert_select 'span.updated_last_by a', false, 'Last editor should not be shown just after creation'
    FactoryBot.create :activity_log, activity_loggable: a, action: 'update', created_at: 10.minute.ago, culprit: person1
    get :show, params: { id: a.id }
    assert_response :success
    assert_select 'span.updated_last_by a', person1.name
    assert_select 'span.updated_last_by a[href=?]', person_path(person1)
    FactoryBot.create :activity_log, activity_loggable: a, action: 'update', created_at: 5.minute.ago, culprit: person1.user
    get :show, params: { id: a.id }
    assert_response :success
    assert_select 'span.updated_last_by a', person1.name
    assert_select 'span.updated_last_by a[href=?]', person_path(person1)
    FactoryBot.create :activity_log, activity_loggable: a, action: 'update', created_at: 1.minute.ago, culprit: person2
    get :show, params: { id: a.id }
    assert_response :success
    assert_select 'span.updated_last_by a', person2.name, 'Correct last editor is being shown'
    assert_select 'span.updated_last_by a[href=?]', person_path(person2)
  end

  test 'last updated by - only shown to members' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    a = FactoryBot.create :assay, policy: FactoryBot.create(:public_policy), created_at: 15.minute.ago, contributor: person1
    FactoryBot.create :activity_log, activity_loggable: a, action: 'create', created_at: 15.minute.ago, culprit: person1
    FactoryBot.create :activity_log, activity_loggable: a, action: 'update', created_at: 10.minute.ago, culprit: person1
    login_as(person1)
    get :show, params: { id: a.id }
    assert_response :success
    assert_select 'span.updated_last_by a', person1.name, 'Last editor should be visible to member'
    login_as(person2)
    get :show, params: { id: a.id }
    assert_response :success, 'Should render ok with non-member user'
    assert_select 'span.updated_last_by a', false, 'Last editor should not be visible to non-member user'
    logout
    get :show, params: { id: a.id }
    assert_response :success, 'Should render ok without user'
    assert_select 'span.updated_last_by a', false, 'Last editor should not be visible to public'
    login_as(person1)
  end

  test 'last updated by - deleted user' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    a = FactoryBot.create :assay, policy: FactoryBot.create(:public_policy), created_at: 15.minute.ago, contributor: person1
    FactoryBot.create :activity_log, activity_loggable: a, action: 'create', created_at: 15.minute.ago, culprit: person1
    FactoryBot.create :activity_log, activity_loggable: a, action: 'update', created_at: 10.minute.ago, culprit: person1
    FactoryBot.create :activity_log, activity_loggable: a, action: 'update', created_at: 1.minute.ago, culprit: person2
    login_as(person1)
    person2.delete
    get :show, params: { id: a.id }
    assert_response :success
    assert_select 'span.updated_last_by a', false, 'Last editor should not be shown if editor user has been deleted'
  end

  test 'should delete empty assay with linked sample type' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    investigation = FactoryBot.create(:investigation, projects: [project], is_isa_json_compliant: true, contributor: person)
    source_st = FactoryBot.create(:isa_source_sample_type, contributor: person, projects: [project])
    sample_collection_st = FactoryBot.create(:isa_sample_collection_sample_type, contributor: person, projects: [project],
    linked_sample_type: source_st)

    study = FactoryBot.create(:study, investigation:, contributor: person,
                              policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: person, access_type: Policy::MANAGING)]),
                              sops: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))],
                              sample_types: [source_st, sample_collection_st])
    assay_stream = FactoryBot.create(:assay_stream, study:, contributor: person)
    assay_sample_type = FactoryBot.create :isa_assay_material_sample_type, linked_sample_type: sample_collection_st,
                                          contributor: person, isa_template: FactoryBot.build(:isa_assay_material_template)
    assay = FactoryBot.create(:assay,
                              study:,
                              policy: FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission,contributor: person, access_type:Policy::EDITING)]),
                              sample_type: assay_sample_type,
                              contributor: person,
                              assay_stream: )


    login_as(person)

    assert assay.is_isa_json_compliant?
    assert assay.sample_type.is_isa_json_compliant?
    assert assay.sample_type.can_delete?

    assert_difference('SampleType.count', -1) do
      assert_difference('Assay.count', -1) do
        delete :destroy, params: { id: assay.id }
      end
    end
  end

  test 'should fix sample type linkage when middle assay is deleted' do
    # person = User.current_user.person
    person = FactoryBot.create(:person)
    project = person.projects.first
    investigation = FactoryBot.create(:investigation, projects: [project], is_isa_json_compliant: true)

    source_st = FactoryBot.create(:isa_source_sample_type, contributor: person, projects: [project])
    sample_collection_st = FactoryBot.create(:isa_sample_collection_sample_type, contributor: person, projects: [project],
                                                                                 linked_sample_type: source_st)


    assay_template_1 = FactoryBot.create(:isa_assay_material_template)
    assay_st1 = FactoryBot.create(:isa_assay_material_sample_type, contributor: person, projects: [project],
                                                          linked_sample_type: sample_collection_st, isa_template: assay_template_1)

    assay_st2 = FactoryBot.create(:isa_assay_material_sample_type, contributor: person, projects: [project],
                                                          linked_sample_type: assay_st1, isa_template: assay_template_1)

    assay_st3 = FactoryBot.create(:isa_assay_material_sample_type, contributor: person, projects: [project],
                                                          linked_sample_type: assay_st2, isa_template: assay_template_1)

    study = FactoryBot.create(:study, investigation: investigation, contributor: person,
                                      policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: person, access_type: Policy::MANAGING)]),
                                      sops: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))],
                                      sample_types: [source_st, sample_collection_st])

    assay_stream = FactoryBot.create(:assay_stream, study:, contributor: person)
    assay1 = FactoryBot.create(:assay, study:, contributor: person, sample_type: assay_st1,
                                       policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: person, access_type: Policy::MANAGING)]),
                                       position: 0, assay_stream: )
    assay2 = FactoryBot.create(:assay, study: study, contributor: person, sample_type: assay_st2,
                                       policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: person, access_type: Policy::MANAGING)]),
                                       position: 1, assay_stream: )
    assay3 = FactoryBot.create(:assay, study: study, contributor: person, sample_type: assay_st3,
                                       policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: person, access_type: Policy::MANAGING)]),
                                       position: 2, assay_stream: )

    login_as(person)

    assert_difference("SampleType.count", -1) do
      assert_difference("Assay.count", -1) do
        delete :destroy, params: { id: assay2.id }
      end
    end

    assay3.reload

    assert_equal(assay3.previous_linked_sample_type&.id, assay1.sample_type&.id)
    assert_equal assay3.position, 1
  end

  test 'do not get index if feature disabled' do
    with_config_value(:isa_enabled, false) do
      get :index
      assert_redirected_to root_path
      assert flash[:error].include?('disabled')
    end
  end

  test 'display single page button if feature enabled' do
    with_config_value(:project_single_page_enabled, true) do
      current_user = FactoryBot.create(:user)
      login_as(current_user)
      assay = FactoryBot.create(:assay, contributor: current_user.person)

      get :show, params: { id: assay }
      assert_response :success

      assert_select 'a', text: 'Single Page', count: 1
    end
  end

  test 'display adjusted buttons if isa json compliant' do
    with_config_value(:isa_json_compliance_enabled, true) do
      current_user = FactoryBot.create(:user)
      project = current_user.person.projects.first
      login_as(current_user)
      investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: current_user.person)
      study = FactoryBot.create(:isa_json_compliant_study, investigation: )
      assay_stream = FactoryBot.create(:assay_stream, study:, contributor: current_user.person)
      get :show, params: { id: assay_stream }
      assert_response :success

      # If stream has no assays, it should say 'Design Assay'
      assert_select 'a', text: /Design #{I18n.t('assay')}/i, count: 1

      assay_sample_type1 = FactoryBot.create(:isa_assay_material_sample_type, linked_sample_type: study.sample_types.second)
      assay1 = FactoryBot.create(:assay, contributor: current_user.person, study:, assay_stream:, sample_type: assay_sample_type1)

      assert_equal assay_stream.study, assay1.study

      get :show, params: { id: assay_stream }
      assert_response :success

      # If stream has child assays, it should say 'Insert a new Assay'
      assert_select 'a', text: /Insert a new #{I18n.t('assay')}/i, count: 1

      get :show, params: { id: assay1 }
      assert_response :success

      # If current assay doesn't have a next assay in the same stream, it should say 'Design the next Assay'
      assert_select 'a', text: /Design the next #{I18n.t('assay')}/i, count: 1

      assay_sample_type2 = FactoryBot.create(:isa_assay_material_sample_type, linked_sample_type: assay_sample_type1)
      assay2 = FactoryBot.create(:assay, contributor: current_user.person, study:, assay_stream:, sample_type: assay_sample_type2)

      get :show, params: { id: assay1 }
      assert_response :success

      # If current assay has a next assay in the same stream, it should say 'Insert a new Assay'
      assert_select 'a', text: /Insert a new #{I18n.t('assay')}/i, count: 1

      get :show, params: { id: assay2 }
      assert_response :success

      # If current assay is at the end of the stream, it should say 'Design the next Assay' again
      assert_select 'a', text: /Design the next #{I18n.t('assay')}/i, count: 1

      source_sample =
        FactoryBot.create :sample,
              title: 'source 1',
              sample_type: study.sample_types.first,
              project_ids: [project.id],
              data: {
                'Source Name': 'Source Name',
                'Source Characteristic 1': 'Source Characteristic 1',
                'Source Characteristic 2':
                  study.sample_types.first
                    .sample_attributes
                    .find_by_title('Source Characteristic 2')
                    .sample_controlled_vocab
                    .sample_controlled_vocab_terms
                    .first
                    .label
              },
              contributor: current_user.person

      sample_sample =
        FactoryBot.create :sample,
              title: 'sample 1',
              sample_type: study.sample_types.second,
              project_ids: [project.id],
              data: {
                Input: [source_sample.id],
                'sample collection': 'sample collection',
                'sample collection parameter value 1': 'sample collection parameter value 1',
                'Sample Name': 'sample name',
                'sample characteristic 1': 'sample characteristic 1'
              },
              contributor: current_user.person

      FactoryBot.create :sample,
        title: 'assay 1 - sample 1',
        sample_type: assay_sample_type1,
        project_ids: [project.id],
        data: {
          Input: [sample_sample.id],
          'Protocol Assay 1': 'Protocol Assay 1',
          'Assay 1 parameter value 1': 'Assay 1 parameter value 1',
          'Extract Name': 'Extract Name',
          'other material characteristic 1': 'other material characteristic 1'
      },
        contributor: current_user.person

      get :show, params: { id: assay_stream }
      assert_response :success

      # If the next assay's sample type has samples, the 'new assay' button should be disabled'
      assert_select 'a', text: /Insert a new #{I18n.t('assay')}/i, class: 'disabled', count: 1

    end
  end

  test 'assay position after deletion' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)
      project = person.projects.first
      login_as(person)
      investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
      study = FactoryBot.create(:isa_json_compliant_study, investigation: )
      assay_stream = FactoryBot.create(:assay_stream, study:, contributor: person, position: 0)

      begin_assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type, linked_sample_type: study.sample_types.second, projects: [project], contributor: person)
      begin_assay = FactoryBot.create(:assay, contributor: person, study:, assay_stream:, sample_type: begin_assay_sample_type, position: 0)

      middle_assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type, linked_sample_type: begin_assay_sample_type, projects: [project], contributor: person)
      middle_assay = FactoryBot.create(:assay, contributor: person, study:, assay_stream:, sample_type: middle_assay_sample_type, position: 1)

      end_assay_sample_type = FactoryBot.create(:isa_assay_data_file_sample_type, linked_sample_type: middle_assay_sample_type, projects: [project], contributor: person)
      end_assay = FactoryBot.create(:assay, contributor: person, study:, assay_stream:, sample_type: end_assay_sample_type, position: 2)

      assert_difference('Assay.count', -1) do
        assert_difference('SampleType.count', -1) do
          delete :destroy, params: {id: middle_assay}
        end
      end

      end_assay.reload
      refute_equal end_assay.position, 2
      assert_equal end_assay.position, 1
    end
  end

  test 'visibility of the propagate permissions button' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)
      login_as(person)
      investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
      study = FactoryBot.create(:isa_json_compliant_study, investigation: )
      assay_stream = FactoryBot.create(:assay_stream, study:, contributor: person, position: 0)
      experimental_assay = FactoryBot.create(:assay, contributor: person, study:, assay_stream:, position: 0)

      get :manage, params: { id: assay_stream }
      assert_response :success
      assert_select 'input[type=checkbox][name=propagate_permissions]', count: 1

      get :manage, params: { id: experimental_assay }
      assert_response :success
      assert_select 'input[type=checkbox][name=propagate_permissions]', count: 0
    end
  end

  test 'should redirect isa json compliant assay to isa assay edit page' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)
      project = person.projects.first
      login_as(person)
      investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
      study = FactoryBot.create(:isa_json_compliant_study, investigation: investigation )
      assay_stream = FactoryBot.create(:assay_stream, study: study, contributor: person)
      assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type, linked_sample_type: study.sample_types.second, projects: [project], contributor: person)
      assay = FactoryBot.create(:assay, contributor: person, study: study, assay_stream:, sample_type: assay_sample_type)

      get :edit, params: { id: assay  }
      assert_redirected_to edit_isa_assay_path(assay)
    end
  end

  test 'Should propagate assay stream permissions' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)
      other_person = FactoryBot.create(:person)
      investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
      study = FactoryBot.create(:isa_json_compliant_study, investigation: )
      assay_stream = FactoryBot.create(:assay_stream, study:, contributor: person, position: 0)

      authorized_child_assay = FactoryBot.create(:assay, contributor: person, study:, assay_stream:, position: 0)

      login_as(person)
      refute authorized_child_assay.can_manage?(other_person)
      patch :manage_update, params: { id: assay_stream, propagate_permissions: '1', assay: {creator_ids: [other_person.id]}, policy_attributes: {access_type: Policy::NO_ACCESS, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}}}

      # assert that the permissions of the authorized assay were propagated
      # other_person should see the assay stream and the authorized assay
      assay_stream.reload
      assert assay_stream.can_manage?(other_person)
      authorized_child_assay.reload
      assert authorized_child_assay.can_manage?(other_person)
    end
  end

  test 'should not propagate assay stream permissions when not authorized' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)
      second_person = FactoryBot.create(:person)
      third_person = FactoryBot.create(:person)

      investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
      study = FactoryBot.create(:isa_json_compliant_study, investigation: )
      assay_stream = FactoryBot.create(:assay_stream, study:, contributor: person, position: 0)
      unauthorized_child_assay = FactoryBot.create(:assay, contributor: second_person, study:, assay_stream:, position: 0)

      login_as(person)
      patch :manage_update, params: { id: assay_stream, propagate_permissions: '1', assay: {creator_ids: [third_person.id]}, policy_attributes: {access_type: Policy::NO_ACCESS, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: third_person.id, access_type: Policy::MANAGING}}}}

      # assert the flash[:error] text. The permissions of the unauthorized assay should not be propagated
      assert flash[:error], "<ul><li>You do not have the necessary permissions to propagate permissions to #{t('assay').downcase} [#{unauthorized_child_assay.id}]: '#{unauthorized_child_assay.title}'</li></ul>"
      assert_redirected_to assay_path(assay_stream)

      # assert that the permissions of the unauthorized assay were not propagated
      # third_person should not see the unauthorized assay but still see the assay stream
      assay_stream.reload
      assert assay_stream.can_manage?(third_person)
      unauthorized_child_assay.reload
      refute unauthorized_child_assay.can_manage?(third_person)
    end
  end
  
  test 'Should not propagate assay stream permissions when propagate_permissions param is not true' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)
      other_person = FactoryBot.create(:person)
      investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
      study = FactoryBot.create(:isa_json_compliant_study, investigation: )
      assay_stream = FactoryBot.create(:assay_stream, study:, contributor: person, position: 0)
      authorized_child_assay = FactoryBot.create(:assay, contributor: person, study:, assay_stream:, position: 0)
      
      login_as(person)
      refute authorized_child_assay.can_manage?(other_person)
      patch :manage_update, params: { id: assay_stream, assay: {creator_ids: [other_person.id] }, policy_attributes: {access_type: Policy::NO_ACCESS, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}}}
      
      assert flash[:error].nil?

      # assert that the permissions of the authorized assay were not propagated
      # other_person should not see the authorized assay
      authorized_child_assay.reload
      refute authorized_child_assay.can_manage?(other_person)

      patch :manage_update, params: { id: assay_stream, propagate_permissions: '0', assay: {creator_ids: [other_person.id] }, policy_attributes: {access_type: Policy::NO_ACCESS, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}}}

      assert flash[:error].nil?

      # assert that the permissions of the authorized assay were not propagated
      # other_person should not see the authorized assay
      authorized_child_assay.reload
      refute authorized_child_assay.can_manage?(other_person)

    end
  end

  test 'can show and edit with deleted contributor' do
    assay = FactoryBot.create(:assay, deleted_contributor:'Person:99', policy: FactoryBot.create(:public_policy))
    assay.update_column(:contributor_id, nil)
    assert assay.can_view?
    assert assay.can_edit?
    assert_nil assay.contributor
    get :show, params: { id: assay.id }
    assert_response :success
    get :edit, params: { id: assay.id }
    assert_response :success
  end

end

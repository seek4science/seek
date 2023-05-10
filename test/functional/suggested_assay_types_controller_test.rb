require 'test_helper'

class SuggestedAssayTypesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    login_as FactoryBot.create(:person)
  end

  test 'should not show manage page for normal user, but show for admins' do
    get :index
    assert_redirected_to root_url

    logout
    login_as FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    get :index
    assert_response :success
  end

  test 'should new' do
    suggested = FactoryBot.create(:suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Fluxomics')
    suggested2 = FactoryBot.create(:suggested_assay_type, parent_id: suggested.id)
    get :new
    assert_response :success
  end

  test 'should show edit own assay types' do
    get :edit, params: { id: FactoryBot.create(:suggested_assay_type, contributor_id: User.current_user.person.try(:id)).id }
    assert_response :success
    assert_not_nil assigns(:suggested_assay_type)
  end

  test 'should create with suggested parent' do
    login_as FactoryBot.create(:admin)
    suggested = FactoryBot.create(:suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Fluxomics')
    assert suggested.children.empty?
    assert_difference('SuggestedAssayType.count') do
      post :create, params: { suggested_assay_type: { label: 'test assay type', parent_uri: "suggested_assay_type:#{suggested.id}" } }
    end
    assert_redirected_to action: :index
    assert suggested.children.count == 1
    get :index
    assert_select 'li a', text: /test assay type/
  end

  test 'should create with ontology parent' do
    login_as FactoryBot.create(:admin)

    assert_difference('SuggestedAssayType.count') do
      post :create, params: { suggested_assay_type: { label: 'test assay type', parent_uri: 'http://jermontology.org/ontology/JERMOntology#Fluxomics' } }
    end
    assert_redirected_to action: :index
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Fluxomics', SuggestedAssayType.last.parent.uri
    get :index
    assert_select 'li a', text: /test assay type/
  end

  test 'should update label' do
    login_as FactoryBot.create(:admin)
    suggested_assay_type = FactoryBot.create(:suggested_assay_type, label: 'old label', contributor_id: User.current_user.person.try(:id))
    put :update, params: { id: suggested_assay_type.id, suggested_assay_type: { label: 'new label' } }
    assert_redirected_to action: :index
    get :index
    assert_select 'li a[href=?]', assay_types_path(uri: suggested_assay_type.uri, label: 'new label'), text: 'new label'
  end

  test 'should update parent' do
    login_as FactoryBot.create(:admin)

    suggested_parent1 = FactoryBot.create(:suggested_assay_type)
    suggested_parent2 = FactoryBot.create(:suggested_assay_type)
    ontology_parent_uri = 'http://jermontology.org/ontology/JERMOntology#Fluxomics'

    suggested_assay_type = FactoryBot.create(:suggested_assay_type, contributor_id: User.current_user.person.try(:id), parent_id: suggested_parent1.id)
    assert_equal 1, suggested_assay_type.parents.size
    assert_equal suggested_parent1, suggested_assay_type.parents.first
    assert_equal suggested_parent1.uri, suggested_assay_type.parent.uri.to_s

    # update to other parent suggested
    put :update, params: { id: suggested_assay_type.id, suggested_assay_type: { parent_uri: "suggested_assay_type:#{suggested_parent2.id}" } }
    assert_redirected_to action: :index
    suggested_parent2.reload
    assert_includes suggested_parent2.children, suggested_assay_type

    # update to other parent from ontology
    put :update, params: { id: suggested_assay_type.id, suggested_assay_type: { parent_uri: ontology_parent_uri } }
    assert_redirected_to action: :index

    ontology_parent = Seek::Ontologies::AssayTypeReader.instance.class_for_uri('http://jermontology.org/ontology/JERMOntology#Fluxomics')
    assert ontology_parent.children.include?(suggested_assay_type)
  end

  test 'should delete assay' do
    # even owner cannot delete own type
    suggested_assay_type = FactoryBot.create(:suggested_assay_type, label: 'delete_me', contributor_id: User.current_user.person.try(:id))
    assert_no_difference('SuggestedAssayType.count') do
      delete :destroy, params: { id: suggested_assay_type.id }
    end
    assert_equal 'Admin rights required to manage types', flash[:error]
    clear_flash(:error)
    logout
    # log in as another user, who is not the owner of the suggested assay type
    login_as FactoryBot.create(:user)
    assert_no_difference('SuggestedAssayType.count') do
      delete :destroy, params: { id: suggested_assay_type.id }
    end

    assert_equal 'Admin rights required to manage types', flash[:error]
    clear_flash(:error)
    logout

    # log in as admin
    login_as FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    assert_difference('SuggestedAssayType.count', -1) do
      delete :destroy, params: { id: suggested_assay_type.id }
    end
    assert_nil flash[:error]
    assert_redirected_to action: :index
  end

  test 'should not delete assay_type with child' do
    login_as FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)

    parent = FactoryBot.create :suggested_assay_type
    child = FactoryBot.create :suggested_assay_type, parent_id: parent.id

    assert_no_difference('SuggestedAssayType.count') do
      delete :destroy, params: { id: parent.id }
    end
    assert flash[:error]
    assert_redirected_to action: :index
  end

  test 'should not delete assay_type with assays' do
    login_as FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)

    suggested_at = FactoryBot.create :suggested_assay_type
    FactoryBot.create(:experimental_assay, suggested_assay_type: suggested_at)
    assert_no_difference('SuggestedAssayType.count') do
      delete :destroy, params: { id: suggested_at.id }
    end
    assert flash[:error]
    assert_redirected_to action: :index
  end

  private

  def http_escape(url)
    ERB::Util.html_escape url
  end
end

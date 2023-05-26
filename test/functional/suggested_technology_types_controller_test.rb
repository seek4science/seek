require 'test_helper'

class SuggestedTechnologyTypesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  setup do
    login_as FactoryBot.create(:user)
    @suggested_technology_type = FactoryBot.create(:suggested_technology_type, contributor_id: User.current_user.person.try(:id)).id
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
    get :new
    assert_response :success
  end

  test 'should show edit on technology types' do
    get :edit, params: { id: @suggested_technology_type }
    assert_response :success
    assert_not_nil assigns(:suggested_technology_type)
  end

  test 'should create with suggested parent' do
    login_as FactoryBot.create(:admin)
    suggested = FactoryBot.create(:suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography')
    assert suggested.children.empty?
    assert_difference('SuggestedTechnologyType.count') do
      post :create, params: { suggested_technology_type: { label: 'test tech type', parent_uri: "suggested_technology_type:#{suggested.id}" } }
    end
    assert_redirected_to action: :index
    assert suggested.children.count == 1
    get :index
    assert_select 'li a', text: /test tech type/
  end

  test 'should create with ontology parent' do
    login_as FactoryBot.create(:admin)

    assert_difference('SuggestedTechnologyType.count') do
      post :create, params: { suggested_technology_type: { label: 'test tech type', parent_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography' } }
    end
    assert_redirected_to action: :index
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography', SuggestedTechnologyType.last.parent.uri
    get :index
    assert_select 'li a', text: /test tech type/
  end

  test 'should update label' do
    login_as FactoryBot.create(:admin)
    put :update, params: { id: @suggested_technology_type, suggested_technology_type: { label: 'new label' } }
    assert_redirected_to action: :index
    get :index
    suggested_technology_type = SuggestedTechnologyType.find @suggested_technology_type
    assert_select 'li a[href=?]', technology_types_path(uri: suggested_technology_type.uri, label: 'new label'), text: 'new label'
  end

  test 'should update parent' do
    login_as FactoryBot.create(:admin)
    suggested_parent1 = FactoryBot.create(:suggested_technology_type)
    suggested_parent2 = FactoryBot.create(:suggested_technology_type)
    ontology_parent_uri = 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography'

    suggested_technology_type = FactoryBot.create(:suggested_technology_type, contributor_id: User.current_user.person.try(:id), parent_id: suggested_parent1.id)
    assert_equal 1, suggested_technology_type.parents.size
    assert_equal suggested_parent1, suggested_technology_type.parents.first
    assert_equal suggested_parent1.uri, suggested_technology_type.parent.uri.to_s

    # update to other parent suggested
    put :update, params: { id: suggested_technology_type.id, suggested_technology_type: { parent_uri: "suggested_technology_type:#{suggested_parent2.id}" } }
    assert_redirected_to action: :index
    suggested_parent2.reload
    assert_includes suggested_parent2.children, suggested_technology_type

    # update to other parent from ontology
    put :update, params: { id: suggested_technology_type.id, suggested_technology_type: { parent_uri: ontology_parent_uri } }
    assert_redirected_to action: :index
  end

  test 'should delete suggested technology type' do
    # even owner cannot delete own type
    assert_no_difference('SuggestedTechnologyType.count') do
      delete :destroy, params: { id: @suggested_technology_type }
    end
    assert_equal 'Admin rights required to manage types', flash[:error]
    clear_flash(:error)
    logout
    # log in as another user, who is not the owner of the suggested technology type
    login_as FactoryBot.create(:user)
    assert_no_difference('SuggestedTechnologyType.count') do
      delete :destroy, params: { id: @suggested_technology_type }
    end

    assert_equal 'Admin rights required to manage types', flash[:error]
    clear_flash(:error)
    logout

    # log in as admin
    login_as FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    assert_difference('SuggestedTechnologyType.count', -1) do
      delete :destroy, params: { id: @suggested_technology_type }
    end
    assert_nil flash[:error]
    assert_redirected_to action: :index
  end

  test 'should not delete technology type with child' do
    login_as FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)

    parent = FactoryBot.create :suggested_technology_type
    child = FactoryBot.create :suggested_technology_type, parent_id: parent.id

    assert_no_difference('SuggestedTechnologyType.count') do
      delete :destroy, params: { id: parent.id }
    end
    assert flash[:error]
    assert_redirected_to action: :index
  end

  test 'should not delete technology type with assays' do
    login_as FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)

    suggested = FactoryBot.create :suggested_technology_type
    FactoryBot.create(:experimental_assay, suggested_technology_type: suggested)
    assert_no_difference('SuggestedTechnologyType.count') do
      delete :destroy, params: { id: suggested.id }
    end
    assert flash[:error]
    assert_redirected_to action: :index
  end
end

require 'test_helper'

class CopasiTest < ActionController::TestCase
  tests ModelsController

  include AuthenticatedTestHelper

  test 'Simulate Model on Copasi button visibility' do

    # if copasi is not enabled, the button is hidden
    model = FactoryBot.create(:copasi_model, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: model }
    assert_response :success
    assert_select 'a[href=?]', copasi_simulate_model_path(model, version: 1), text: 'Simulate Model on Copasi', count:0


    # if copasi is enabled, the button is visible
    Seek::Config.copasi_enabled = true
    model = FactoryBot.create(:copasi_model, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: model }
    assert_response :success
    assert_select 'a[href=?]', copasi_simulate_model_path(model, version: 1), text: 'Simulate Model on Copasi'


    # for the creator of a private model, the button is visible
    model = FactoryBot.create(:copasi_model, policy: FactoryBot.create(:private_policy))
    login_as(model.contributor.user)
    assert model.can_download?(User.current_user)
    get :show, params: { id: model }
    assert_response :success
    assert_select 'a[href=?]', copasi_simulate_model_path(model, version: 1), text: 'Simulate Model on Copasi'


    # for another user, the button is hidden
    person = FactoryBot.create(:person)
    login_as(person)
    get :show, params: { id: model }
    assert_response :forbidden

    # when granting the user the access right, the button is visible
    model.policy.permissions << FactoryBot.create(:permission, contributor:person, access_type:Policy::ACCESSIBLE)
    get :show, params: { id: model }
    assert_response :success
    assert_select 'a[href=?]', copasi_simulate_model_path(model, version: 1), text: 'Simulate Model on Copasi'

    # for a COPASI not compatible model, the button is hidden.
    model = FactoryBot.create(:non_sbml_xml_model, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: model }
    assert_response :success
    assert_select 'a[href=?]', copasi_simulate_model_path(model, version: 1), text: 'Simulate Model on Copasi', count:0

  end

end

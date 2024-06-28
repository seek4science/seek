require 'test_helper'

class CopasiTest < ActionController::TestCase
  tests ModelsController

  include AuthenticatedTestHelper

  test 'simulate model on copasi button visibility' do

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



  test 'copasi simulate when model is public' do

    Seek::Config.copasi_enabled = true
    model = FactoryBot.create(:copasi_model, policy: FactoryBot.create(:public_policy))
    get :copasi_simulate, params: { id: model.id, version: model.version }
    assert_response :success

    assert_select 'h1', text: /#{model.title} - Copasi Model Simulation/
    assert_select 'a[onclick="simulate()"]', text: 'Simulate Online'

    # Assert the presence of the <a> tag with the specific href attribute and text
    expected_href = "copasi://process?downloadUrl=http://#{request.host_with_port}/models/#{model.id}/content_blobs/#{model.content_blobs.first.id}/download&activate=Time%20Course&createPlot=Concentrations%2C%20Volumes%2C%20and%20Global%20Quantity%20Values&runTask=Time-Course"
    assert_select 'a[href=?]', expected_href, text: 'Simulate in CopasiUI'

  end

  test 'copasi simulate when model is private' do

    Seek::Config.copasi_enabled = true
    model = FactoryBot.create(:copasi_model, policy: FactoryBot.create(:private_policy))
    login_as(model.contributor.user)
    assert model.can_download?(User.current_user)

    assert_difference('SpecialAuthCode.count') do
      get :copasi_simulate, params: { id: model.id, version: model.version }
    end

    assert_response :success

    auth_code = CGI.escape(model.special_auth_codes.first.code)
    assert_match /^copasi_/, model.special_auth_codes.first.code

    assert_select 'h1', text: /#{model.title} - Copasi Model Simulation/
    assert_select 'a[onclick="simulate()"]', text: 'Simulate Online'
    assert_select 'a[href*=?]', auth_code, text: 'Simulate in CopasiUI'

    assert_no_difference('SpecialAuthCode.count') do
      get :copasi_simulate, params: { id: model.id, version: model.version }
    end

    assert_select 'a[onclick="simulate()"]', text: 'Simulate Online'
    assert_select 'a[href*=?]', auth_code, text: 'Simulate in CopasiUI'

  end

end

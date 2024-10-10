require 'test_helper'

class CopasiTest < ActionController::TestCase
  tests ModelsController

  include AuthenticatedTestHelper

  test 'simulate model on copasi button visibility' do

    # if copasi is not enabled, the button is hidden
    Seek::Config.copasi_enabled = false
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

    assert_difference('model.run_count', 1) do
      get :copasi_simulate, params: { id: model.id, version: model.version }
    end

    assert_response :success

    assert_equal [], model.special_auth_codes.reload

    assert_select 'h1', text: /#{model.title} - Copasi Model Simulation/
    assert_select 'a[onclick="simulate()"]', text: 'Simulate Online'

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
    assert_match /^copasi_/, auth_code

    assert_select 'h1', text: /#{model.title} - Copasi Model Simulation/
    assert_select 'a[onclick="simulate()"]', text: 'Simulate Online'
    assert_select 'a[href*=?]', auth_code, text: 'Simulate in CopasiUI'

    # the copasi code will expire in 1 day
    assert_no_difference('SpecialAuthCode.count') do
      get :copasi_simulate, params: { id: model.id, version: model.version }
    end

    assert_select 'a[onclick="simulate()"]', text: 'Simulate Online'
    assert_select 'a[href*=?]', auth_code, text: 'Simulate in CopasiUI'

    # new copasi code will be generated after 1 day
    travel_to(Time.now + 1.day) do
      assert_difference('SpecialAuthCode.count') do
        get :copasi_simulate, params: { id: model.id, version: model.version }
      end
    end
  end

  test 'simulate copasi when model is private' do
    Seek::Config.copasi_enabled = true

    # no login, no access right for the private model
    model = FactoryBot.create(:copasi_model, policy: FactoryBot.create(:private_policy))

    assert_no_difference('model.run_count') do
      get :copasi_simulate, params: { id: model.id, version: model.version }
    end

    assert_select 'h2', text: /The Model is not visible to you./

    # login as another user, no access right for the private model
    person = FactoryBot.create(:person)
    login_as(person)

    assert_no_difference('model.run_count') do
      get :copasi_simulate, params: { id: model.id, version: model.version }
    end
    assert_select 'h2', text: /The Model is not visible to you./

    # the access right granted by the model owner, the another user can simulate the model
    login_as(model.contributor.user)
    model.policy.permissions << FactoryBot.create(:permission, contributor:person, access_type:Policy::ACCESSIBLE)
    assert_difference('model.run_count', 1) do
      get :copasi_simulate, params: { id: model.id, version: model.version }
    end
    assert_response :success

    assert_select 'a[onclick="simulate()"]', text: 'Simulate Online'

  end

  test 'should simulate the correct version' do

    Seek::Config.copasi_enabled = true
    model = FactoryBot.create(:copasi_model, policy: FactoryBot.create(:public_policy))

    get :copasi_simulate, params: { id: model.id, version: 1 }
    assert_response :success
    assert_select 'div.version', text:/Version 1/


    assert_difference('Model::Version.count', 1) do
      post :create_version, params: { id: model, model: { title: model.title },
                                      content_blobs:[{ data: fixture_file_upload('Teusink.xml') }],
                                      revision_comments: 'This is a new revision'}

      assert_redirected_to model_path(assigns(:model))
    end

    get :copasi_simulate, params: { id: model.id, version: 2 }
    assert_response :success
    assert_select 'div.version', text:/Version 2/

    assert_difference('Model::Version.count', 1) do
      post :create_version, params: { id: model, model: { title: model.title },
                                      content_blobs:[{ data: fixture_file_upload('little_file.txt') }],
                                      revision_comments: 'This is a new revision'}

      get :copasi_simulate, params: { id: model.id, version: 3 }
      assert_response :success
      assert_select 'div.version', text:/Version 3/
      assert_select 'div#error_flash', text:/The selected version does not contain a format supported by COPASI./

    end
  end


  test 'show run count for runnable copasi model' do
    Seek::Config.copasi_enabled = true
    model = FactoryBot.create(:copasi_model, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: model }

    assert_select '#usage_count' do
      assert_select 'strong', text: /Downloads/, count: 1
      assert_select 'strong', text: /Runs:/, count: 1
    end
  end

  test 'do not show run count for non-runnable copasi model' do

    model = FactoryBot.create(:non_sbml_xml_model, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: model }
    assert_response :success

    assert_select '#usage_count' do
      assert_select 'strong', text: /Downloads/, count: 1
      assert_select 'strong', text: /Runs:/, count: 0
    end
  end


end

require 'test_helper'

class MorpheusTest < ActionController::TestCase
  tests ModelsController

  include AuthenticatedTestHelper

  test 'simulate model on morpheus button visibility' do
    def morpheus_download_path(model)
      blob = model.content_blobs.first
      "morpheus://#{request.host_with_port}/models/#{model.id}/content_blobs/#{blob.id}/download"
    end

    public_model = FactoryBot.create(:morpheus_model, policy: FactoryBot.create(:public_policy))
    teusink_model = FactoryBot.create(:teusink_jws_model, policy: FactoryBot.create(:public_policy))
    private_model = FactoryBot.create(:morpheus_model, policy: FactoryBot.create(:private_policy))

    # for a public Morpheus model, if Morpheus is not enabled, the button is hidden
    with_config_value(:morpheus_enabled, false) do
      get :show, params: { id: public_model }
      assert_response :success
      assert_select 'a[href=?]', morpheus_download_path(public_model), text: 'Simulate in MorpheusUI', count: 0
    end

    # for a public Morpheus model, if Morpheus is enabled, the button is shown
    with_config_value(:morpheus_enabled, true) do
      get :show, params: { id: public_model }
      assert_response :success
      assert_select 'a[href=?]', morpheus_download_path(public_model), text: 'Simulate in MorpheusUI', count: 1
    end

    # for a non-compatible Morpheus model, the button is hidden
    with_config_value(:morpheus_enabled, true) do
      get :show, params: { id: teusink_model }
      assert_response :success
      assert_select 'a[href=?]', morpheus_download_path(teusink_model), text: 'Simulate in MorpheusUI', count: 0
    end

    # for a private Morpheus model, the button is hidden
    login_as(private_model.contributor.user)
    with_config_value(:morpheus_enabled, true) do
      get :show, params: { id: private_model }
      assert_response :success
      assert_select 'a[href=?]', morpheus_download_path(private_model), text: 'Simulate in MorpheusUI', count: 0
    end
  end

end

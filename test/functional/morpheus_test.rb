require 'test_helper'

class MorpheusTest < ActionController::TestCase
  tests ModelsController

  include AuthenticatedTestHelper

  def morpheus_download_path(model)
    blob = model.content_blobs.first
    "morpheus://#{request.host_with_port}/models/#{model.id}/content_blobs/#{blob.id}/download"
  end

  test 'simulate model on morpheus button visibility when Morpheus is disabled' do
    public_model = FactoryBot.create(:morpheus_model, policy: FactoryBot.create(:public_policy))

    with_config_value(:morpheus_enabled, false) do
      get :show, params: { id: public_model }
      assert_response :success
      assert_select 'a[href=?]', morpheus_download_path(public_model), text: 'Simulate in MorpheusUI', count: 0
    end
  end

  test 'simulate model on morpheus button visibility when Morpheus is enabled' do
    public_model = FactoryBot.create(:morpheus_model, policy: FactoryBot.create(:public_policy))

    with_config_value(:morpheus_enabled, true) do
      get :show, params: { id: public_model }
      assert_response :success
      assert_select 'a[href=?]', morpheus_download_path(public_model), text: 'Simulate in MorpheusUI', count: 1
    end
  end

  test 'simulate model on morpheus button visibility for non-compatible model' do
    teusink_model = FactoryBot.create(:teusink_jws_model, policy: FactoryBot.create(:public_policy))

    with_config_value(:morpheus_enabled, true) do
      get :show, params: { id: teusink_model }
      assert_response :success
      assert_select 'a[href=?]', morpheus_download_path(teusink_model), text: 'Simulate in MorpheusUI', count: 0
    end
  end

  test 'simulate model on morpheus button visibility for private model' do
    private_model = FactoryBot.create(:morpheus_model, policy: FactoryBot.create(:private_policy))
    login_as(private_model.contributor.user)

    with_config_value(:morpheus_enabled, true) do
      get :show, params: { id: private_model }
      assert_response :success
      assert_select 'a[href=?]', morpheus_download_path(private_model), text: 'Simulate in MorpheusUI', count: 0
    end
  end
end
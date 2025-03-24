require 'test_helper'

class ModelImagesControllerTest < ActionController::TestCase
  fixtures :models, :users

  include AuthenticatedTestHelper

  test 'get model image' do
    model = FactoryBot.create(:model_with_image, policy: FactoryBot.create(:public_policy))
    get :show, params: { model_id: model.id, id: model.model_image.id }
    assert_response :success
    assert_equal 'image/png', @response.header['Content-Type']
    assert_equal "inline; filename=\"#{model.model_image.id}.png\"; filename*=UTF-8''#{model.model_image.id}.png", @response.header['Content-Disposition']
    expected_size = File.size(model.model_image.file_path).to_s
    assert_equal expected_size, @response.header['Content-Length']
  end

  test 'get model image with size' do
    model = FactoryBot.create(:model_with_image, policy: FactoryBot.create(:public_policy))
    get :show, params: { model_id: model.id, id: model.model_image.id, size: '10x10' }
    assert_response :success
    assert_equal 'image/png', @response.header['Content-Type']
    assert_equal "inline; filename=\"#{model.model_image.id}.png\"; filename*=UTF-8''#{model.model_image.id}.png", @response.header['Content-Disposition']
    expected_size = File.size(model.model_image.full_cache_path('10x10')).to_s
    assert_equal expected_size, @response.header['Content-Length']
  end

  test 'model_image is authorised by model' do
    model = FactoryBot.create(:model_with_image, policy: FactoryBot.create(:private_policy))
    get :show, params: { model_id: model.id, id: model.model_image.id }
    assert_redirected_to root_path
    assert_not_nil flash[:error]
    assert_equal "You can only view images for #{I18n.t('model').pluralize} you can access", flash[:error]
  end

  test 'get the maximum size for the image' do
    model = FactoryBot.create(:model_with_image, policy: FactoryBot.create(:public_policy))
    get :show, params: { model_id: model.id, id: model.model_image.id, size: '5000x5000' }
    assert_response :success
    assert_equal 'image/png', @response.header['Content-Type']
    assert_equal "inline; filename=\"#{model.model_image.id}.png\"; filename*=UTF-8''#{model.model_image.id}.png", @response.header['Content-Disposition']
    expected_size = File.size(model.model_image.full_cache_path('5000x5000')).to_s
    assert_equal expected_size, @response.header['Content-Length']
  end
end

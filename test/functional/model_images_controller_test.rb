require 'test_helper'

class ModelImagesControllerTest < ActionController::TestCase
  fixtures :models, :users

  include AuthenticatedTestHelper
          :users
  test 'breadcrumb for model image index' do
      login_as(:quentin)
      model = models(:jws_model)
      get :index,:model_id => model.id
      assert_response :success
      assert_select 'div.breadcrumbs', :text => /Home > Models Index > #{model.title} > Edit > Model images Index/, :count => 1 do
        assert_select "a[href=?]", root_path, :count => 1
        assert_select "a[href=?]", models_url, :count => 1
        assert_select "a[href=?]", model_url(model), :count => 1
      end
    end

    test 'breadcrumb for uploading new model image' do
      login_as(:quentin)
      model = models(:jws_model)
      get :new,:model_id => model.id
      assert_response :success
      assert_select 'div.breadcrumbs', :text => /Home > Models Index > #{model.title} > Edit > Model images Index > New/, :count => 1 do
        assert_select "a[href=?]", root_path, :count => 1
        assert_select "a[href=?]", models_url, :count => 1
        assert_select "a[href=?]", model_url(model), :count => 1
        assert_select "a[href=?]", model_model_images_url(model), :count => 1
      end
    end

end

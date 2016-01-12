require 'test_helper'

class DataSharePacksControllerTest < ActionController::TestCase
  setup do
    @data_share_pack = data_share_packs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_share_packs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create data_share_pack" do
    assert_difference('DataSharePack.count') do
      post :create, data_share_pack: { [title: @data_share_pack.[title, description: @data_share_pack.description }
    end

    assert_redirected_to data_share_pack_path(assigns(:data_share_pack))
  end

  test "should show data_share_pack" do
    get :show, id: @data_share_pack
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @data_share_pack
    assert_response :success
  end

  test "should update data_share_pack" do
    put :update, id: @data_share_pack, data_share_pack: { [title: @data_share_pack.[title, description: @data_share_pack.description }
    assert_redirected_to data_share_pack_path(assigns(:data_share_pack))
  end

  test "should destroy data_share_pack" do
    assert_difference('DataSharePack.count', -1) do
      delete :destroy, id: @data_share_pack
    end

    assert_redirected_to data_share_packs_path
  end
end

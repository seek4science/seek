require 'test_helper'
require 'jws_online_test_helper'

class JwsOnlineTest < ActionController::TestCase

  tests ModelsController

  include AuthenticatedTestHelper
  include JwsOnlineTestHelper

  test "simulate button visibility" do
    model = Factory(:teusink_model,:policy=>Factory(:public_policy))
    get :show,:id=>model
    assert_response :success
    assert_select "ul.sectionIcons li a[href=?]",simulate_model_path(model,:version=>1)

    model = Factory(:non_sbml_xml_model,:policy=>Factory(:public_policy))
    get :show,:id=>model
    assert_response :success
    assert_select "ul.sectionIcons li a[href=?]",simulate_model_path(model,:version=>1),:count=>0

    model = Factory(:teusink_model,:policy=>Factory(:publicly_viewable_policy))
    get :show,:id=>model
    assert_response :success
    assert_select "ul.sectionIcons li a[href=?]",simulate_model_path(model,:version=>1), :count=>0
  end

  test "simulate" do
    model = Factory(:teusink_model,:policy=>Factory(:public_policy))
    post :simulate,:id=>model.id
    assert_response :success
    assert assigns(:simulate_url)

    url = assigns(:simulate_url)
    refute_nil url
    assert url =~ URI::regexp,"simulate url (#{url}) should be a valid url"
    assert_select "iframe[src=?]",url
  end

end
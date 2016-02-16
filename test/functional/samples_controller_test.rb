require 'test_helper'

class SamplesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'new' do
    login_as(Factory(:person))
    get :new
    assert_response :success
    assert assigns(:sample)
  end

  test 'new with sample type id' do
    login_as(Factory(:person))
    type = Factory(:patient_sample_type)
    get :new,sample_type_id:type.id
    assert_response :success
    assert assigns(:sample)
    assert_equal type,assigns(:sample).sample_type
  end

end

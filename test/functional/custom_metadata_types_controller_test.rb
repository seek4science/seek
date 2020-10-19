require 'test_helper'

class CustomMetadataTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'get form fields' do
    cmt = Factory(:simple_investigation_custom_metadata_type)

    login_as(Factory(:person))

    get :form_fields, params:{id:cmt.id}

    assert_select "input#investigation_custom_metadata_attributes_data_age[name=?]","investigation[custom_metadata_attributes][data][age]"
    assert_select "input#investigation_custom_metadata_attributes_data_name[name=?]","investigation[custom_metadata_attributes][data][name]"
    assert_select "input#investigation_custom_metadata_attributes_data_date[name=?]","investigation[custom_metadata_attributes][data][date]"

  end

end

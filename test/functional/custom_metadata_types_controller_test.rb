require 'test_helper'

class CustomMetadataTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'get form fields' do
    cmt = Factory(:simple_investigation_custom_metadata_type)

    login_as(Factory(:person))

    get :form_fields, params:{id:cmt.id}

    assert_select "input#investigation_custom_metadata_attributes__custom_metadata_age[name=?]",'investigation[custom_metadata_attributes][_custom_metadata_age]'
    assert_select "input#investigation_custom_metadata_attributes__custom_metadata_name[name=?]",'investigation[custom_metadata_attributes][_custom_metadata_name]'
    assert_select "input#investigation_custom_metadata_attributes__custom_metadata_date[name=?]",'investigation[custom_metadata_attributes][_custom_metadata_date]'

  end

end

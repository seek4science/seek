require 'test_helper'

class CustomMetadataTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'get form fields' do
    cmt = Factory(:simple_investigation_custom_metadata_type)

    login_as(Factory(:person))

    get :form_fields, params:{id:cmt.id}

    assert_select "input#investigation_custom_metadata_attributes_#{Seek::JSONMetadata::METHOD_PREFIX}age[name=?]","investigation[custom_metadata_attributes][#{Seek::JSONMetadata::METHOD_PREFIX}age]"
    assert_select "input#investigation_custom_metadata_attributes_#{Seek::JSONMetadata::METHOD_PREFIX}name[name=?]","investigation[custom_metadata_attributes][#{Seek::JSONMetadata::METHOD_PREFIX}name]"
    assert_select "input#investigation_custom_metadata_attributes_#{Seek::JSONMetadata::METHOD_PREFIX}date[name=?]","investigation[custom_metadata_attributes][#{Seek::JSONMetadata::METHOD_PREFIX}date]"

  end

end

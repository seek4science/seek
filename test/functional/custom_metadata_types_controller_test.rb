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

  test 'show help text' do
    cmt = Factory(:simple_investigation_custom_metadata_type_with_description_and_label)
    login_as(Factory(:person))
    get :form_fields, params:{id:cmt.id}
    assert_select 'small', 'You need to enter age.'
    assert_select 'small', 1
    assert_select 'p.help-block', 1
    assert_select 'label',  text:'Biological age', count:1
    assert_select 'label',  text:'Date', count:1
  end

end

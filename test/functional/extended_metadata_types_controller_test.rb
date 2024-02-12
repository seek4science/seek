require 'test_helper'

class ExtendedMetadataTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'get form fields' do
    cmt = FactoryBot.create(:simple_investigation_extended_metadata_type)

    login_as(FactoryBot.create(:person))

    get :form_fields, params:{id:cmt.id}
    assert_response :success

    assert_select "input#investigation_extended_metadata_attributes_data_age[name=?]","investigation[extended_metadata_attributes][data][age]"
    assert_select "input#investigation_extended_metadata_attributes_data_name[name=?]","investigation[extended_metadata_attributes][data][name]"
    assert_select "input#investigation_extended_metadata_attributes_data_date[name=?]","investigation[extended_metadata_attributes][data][date]"

  end

  test 'show help text' do
    cmt = FactoryBot.create(:simple_investigation_extended_metadata_type_with_description_and_label)
    login_as(FactoryBot.create(:person))
    get :form_fields, params:{id:cmt.id}
    assert_select 'small', 'You need to enter age.'
    assert_select 'small', 1
    assert_select 'p.help-block', 1
    assert_select 'label',  text:'Biological age', count:1
    assert_select 'label',  text:'Date', count:1
  end

  test 'can access administer as admin' do
    person = FactoryBot.create(:admin)
    login_as(person)
    get :administer
    assert_response :success
    refute flash[:error]
  end

  test 'can access administer as project admin' do
    person = FactoryBot.create(:project_administrator)
    login_as(person)
    get :administer
    assert_redirected_to :root
    assert flash[:error]
  end

end

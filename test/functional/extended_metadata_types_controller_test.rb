require 'test_helper'

class ExtendedMetadataTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  fixtures :sample_attribute_types

  test 'get form fields' do
    cmt = FactoryBot.create(:simple_investigation_extended_metadata_type)

    login_as(FactoryBot.create(:person))

    get :form_fields, params:{id:cmt.id}
    assert_response :success

    assert_select "input#investigation_extended_metadata_attributes_data_age[name=?]","investigation[extended_metadata_attributes][data][age]"
    assert_select "input#investigation_extended_metadata_attributes_data_name[name=?]","investigation[extended_metadata_attributes][data][name]"
    assert_select "input#investigation_extended_metadata_attributes_data_date[name=?]","investigation[extended_metadata_attributes][data][date]"

  end

  test 'administer update enabled' do
    emt = FactoryBot.create(:simple_investigation_extended_metadata_type)
    person = FactoryBot.create(:admin)
    login_as(person)

    assert emt.enabled?

    put :administer_update, params:{id: emt.id, extended_metadata_type: {enabled: false}}
    assert_redirected_to administer_extended_metadata_types_path
    refute emt.reload.enabled?

    put :administer_update, params:{id: emt.id, extended_metadata_type: {enabled: true}}
    assert_redirected_to administer_extended_metadata_types_path
    assert emt.reload.enabled?
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

  test 'administer' do
    emt = FactoryBot.create(:simple_investigation_extended_metadata_type)
    person = FactoryBot.create(:admin)
    login_as(person)
    get :administer
    assert_response :success
    refute flash[:error]
    assert_select 'div.tab-content div.tab-pane', count: 4
    assert_select 'div.tab-content div.tab-pane.active', count: 1
    assert_select 'table tbody tr:not(.emt-partition-title) td', text: emt.title
    assert_select "a[href=?]", new_extended_metadata_type_path, text: 'Create Extended Metadata Type'
    assert_select 'li.nav-item > a', count: 4
    assert_select 'li.nav-item > a', text: 'Top Level'
    assert_select 'li.nav-item > a', text: 'Nested Level'
    assert_select 'li.nav-item > a', text: 'Controlled Vocabs'
    assert_select 'li.nav-item > a', text: 'Extended Metadata Attribute Types'
  end

  test 'administer table - disabled as text-secondary' do
    emt = FactoryBot.create(:simple_investigation_extended_metadata_type)
    person = FactoryBot.create(:admin)
    login_as(person)
    get :administer
    assert_select 'table tr.text-secondary', count: 0

    emt.update_column(:enabled, false)
    get :administer
    assert_select 'table tr.text-secondary', count: 1
  end

  test 'can access administer as admin' do
    person = FactoryBot.create(:admin)
    login_as(person)
    get :administer
    assert_response :success
  end

  test 'cannot access administer as project admin' do
    person = FactoryBot.create(:project_administrator)
    login_as(person)
    get :administer
    assert_redirected_to :root
    assert flash[:error]
    assert_equal 'Admin rights required', flash[:error]
  end

  test 'can new as admin' do
    person = FactoryBot.create(:admin)
    login_as(person)
    get :new
    assert_response :success
  end

  test 'cannot new as non-admin' do
    person = FactoryBot.create(:person)
    login_as(person)
    get :new
    assert_redirected_to :root
    assert_equal 'Admin rights required', flash[:error]
  end

  test 'should get new fair data station enabled shows tab' do
    person = FactoryBot.create(:admin)
    login_as(person)
    with_config_value(:fair_data_station_enabled, true) do
      get :new
    end
    assert_response :success
    assert_select 'ul#extended-metadata-type-tabs' do
      assert_select 'li', count: 2
      assert_select 'li a[href=?]', '#from-fair-ds-ttl'
    end
  end

  test 'should get new fair data station disabled shows no tab' do
    person = FactoryBot.create(:admin)
    login_as(person)
    with_config_value(:fair_data_station_enabled, false) do
      get :new
    end
    assert_response :success
    assert_select 'ul#extended-metadata-type-tabs' do
      assert_select 'li', count: 1
      assert_select 'li a[href=?]', '#from-fair-ds-ttl', count: 0
    end
  end


  test 'should create successfully' do
    person = FactoryBot.create(:admin)
    login_as(person)

    file = fixture_file_upload('extended_metadata_type/valid_simple_emt.json', 'application/json')

    assert_difference('ExtendedMetadataType.count') do
      post :create, params: { emt_json_file: file }
    end
    emt = assigns(:extended_metadata_type)
    assert_redirected_to administer_extended_metadata_types_path(emt: emt.id)
    assert_equal 'Extended metadata type was successfully created.', flash[:notice]
  end

  test 'upload file with no file selected' do
    person = FactoryBot.create(:admin)
    login_as(person)

    post :create, params: { emt_json_file: nil }

    assert_redirected_to new_extended_metadata_type_path
    assert_equal 'Please select a file to upload!', flash[:error]
  end

  test 'should not create when the resource doesnt support extended metadata' do
    person = FactoryBot.create(:admin)
    login_as(person)

    file = fixture_file_upload('extended_metadata_type/invalid_not_supported_type_emt.json', 'application/json')

    assert_no_difference('ExtendedMetadataType.count') do
      post :create, params: { emt_json_file: file }
    end

    assert_equal "Supported type  'Publication' does not support extended metadata!", flash[:error]

  end

  test 'should not create when the supported type is invalid' do
    person = FactoryBot.create(:admin)
    login_as(person)

    file = fixture_file_upload('extended_metadata_type/invalid_supported_type_emt.json', 'application/json')

    assert_no_difference('ExtendedMetadataType.count') do
      post :create, params: { emt_json_file: file }
    end

    assert_equal "Supported type 'Journal' is not a valid support type!", flash[:error]
  end


  test 'can display extended metadata types' do
    person = FactoryBot.create(:admin)
    login_as(person)

    FactoryBot.create(:study_extended_metadata_type_with_cv_and_cv_list_type)
    FactoryBot.create(:simple_investigation_extended_metadata_type)
    FactoryBot.create(:role_extended_metadata_type )

    get :administer
    assert_response :success

    abc = assigns(:administer)


    assert_select 'ul.nav-tabs' do
      assert_select 'li a[href=?]', '#top-level-metadata-table', text: 'Top Level'
      assert_select 'li a[href=?]', '#nested-metadata-table', text: 'Nested Level'
      assert_select 'li a[href=?]', '#sample-controlled-vocabs', text: 'Controlled Vocabs'
      assert_select 'li a[href=?]', '#sample-attribute-types', text: 'Extended Metadata Attribute Types'
    end


    assert_select 'div#top-level-metadata-table tbody tr', count: 3
    assert_select 'div#nested-metadata-table tbody tr', count: 1
    assert_select 'div#sample-controlled-vocabs tbody tr', count: 2

    assert_select 'div#nested-metadata-table tbody tr' do
      assert_select 'td', text: 'role_name'
      assert_select 'td', text: 'ExtendedMetadata'
      assert_select 'td', text: '1'
    end

    assert_select 'div#top-level-metadata-table tbody tr' do
      assert_select 'td', text: 'simple investigation extended metadata type'
      assert_select 'td', text: 'Investigation'
      assert_select 'td', text: '0'
    end

    assert_select 'div#sample-controlled-vocabs tbody tr' do
      assert_select 'td', text: SampleControlledVocab.first.title
      assert_select 'td', text: SampleControlledVocab.last.title
    end

  end



  test 'successfully deletes extended metadata type' do
    emt = FactoryBot.create(:simple_investigation_extended_metadata_type)
    person = FactoryBot.create(:admin)
    login_as(person)

    assert_difference('ExtendedMetadataType.count', -1) do
      delete :destroy, params: { id: emt.id }
    end

    assert_redirected_to administer_extended_metadata_types_path
    assert_equal 'Extended metadata type was successfully deleted.', flash[:notice]
  end

  test 'can not delete extended metadata type if there are the existing extended metadata instances based on it' do
    em = FactoryBot.create(:simple_extended_metadata)
    emt = em.extended_metadata_type

    person = FactoryBot.create(:admin)
    login_as(person)

    assert_no_difference('ExtendedMetadataType.count') do
      delete :destroy, params: { id: emt.id }
    end
  end


  test 'can not delete the nested extended metadata type if it has been linked by other Extended metadata types' do

    em = FactoryBot.create(:family_extended_metadata)
    emt = em.extended_metadata_type

    person = FactoryBot.create(:admin)
    login_as(person)

    assert_no_difference('ExtendedMetadataType.count') do
      delete :destroy, params: { id: emt.id }
    end

    nested_emt = emt.metadata_attributes.find(&:linked_extended_metadata_or_multi?).linked_extended_metadata_type

    assert_no_difference('ExtendedMetadataType.count') do
      delete :destroy, params: { id: nested_emt.id }
    end

  end

  test 'activity logging' do

    person = FactoryBot.create(:admin)
    login_as(person)

    file = fixture_file_upload('extended_metadata_type/valid_simple_emt.json', 'application/json')

    assert_difference('ActivityLog.count') do
      post :create, params: { emt_json_file: file }
    end

    emt = assigns(:extended_metadata_type)
    
    log = ActivityLog.last
    assert_equal emt, log.activity_loggable
    assert_equal 'create', log.action
    assert_equal person.user, log.culprit

    assert_difference('ActivityLog.count') do
      delete :destroy, params: { id: emt.id }
    end

  end

  # FAIR Data Station TTL

  test 'none-admin cannot create from ttl' do
    person = FactoryBot.create(:person)
    refute person.is_admin?
    login_as(person)

    file = fixture_file_upload('fair_data_station/seek-fair-data-station-test-case.ttl', 'text/turtle')

    assert_no_difference('ExtendedMetadataType.count') do
      with_config_value(:fair_data_station_enabled, true) do
        post :create_from_fair_ds_ttl, params: { emt_fair_ds_ttl_file: file }
      end
    end
    assert_redirected_to :root
    assert_equal 'Admin rights required', flash[:error]
  end

  test 'create from ttl' do
    person = FactoryBot.create(:admin)
    assert person.is_admin?
    login_as(person)

    file = fixture_file_upload('fair_data_station/seek-fair-data-station-test-case-irregular.ttl', 'text/turtle')

    assert_no_difference('ExtendedMetadataType.count') do
      assert_no_difference('ActivityLog.count') do
        with_config_value(:fair_data_station_enabled, true) do
          post :create_from_fair_ds_ttl, params: { emt_fair_ds_ttl_file: file }
        end
      end
    end
    assert_response :success
    assert_equal 4, assigns(:jsons).count
    assert_empty assigns(:existing_extended_metadata_types)
    assert_select 'div.panel.extended-metadata-type-preview', count: 4
    assert_select 'table.extended-metadata-type-attributes', count: 4
    assert_select 'table.extended-metadata-type-attributes tbody tr', count: 10
    assert_select 'a.btn[href=?]', administer_extended_metadata_types_path, text:'Cancel'
    assert_select 'input.btn[type="submit"][value="Create"]'
  end

  test 'create from ttl with existing study and assay' do
    person = FactoryBot.create(:admin)
    study_emt = FactoryBot.create(:fairdata_test_case_study_extended_metadata)
    assay_emt = FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    assert person.is_admin?
    login_as(person)

    file = fixture_file_upload('fair_data_station/seek-fair-data-station-test-case-irregular.ttl', 'text/turtle')

    assert_no_difference('ExtendedMetadataType.count') do
      with_config_value(:fair_data_station_enabled, true) do
        post :create_from_fair_ds_ttl, params: { emt_fair_ds_ttl_file: file }
      end
    end
    assert_response :success
    assert_equal 2, assigns(:jsons).count
    assert_equal [study_emt, assay_emt], assigns(:existing_extended_metadata_types)
    assert_select 'div.panel.extended-metadata-type-preview', count: 2
    assert_select 'table.extended-metadata-type-attributes', count: 2
    assert_select 'table.extended-metadata-type-attributes tbody tr', count: 4
    assert_select 'a.btn[href=?]', administer_extended_metadata_types_path, text:'Cancel'
    assert_select 'input.btn[type="submit"][value="Create"]'

    assert_select 'ul.existing-extended-metadata-types' do
      assert_select 'li', count: 2
      assert_select 'li', text: "Study : #{study_emt.title}"
      assert_select 'li', text: "Assay : #{assay_emt.title}"
    end
  end

  test 'create from ttl no results' do
    person = FactoryBot.create(:admin)
    assert person.is_admin?
    login_as(person)

    file = fixture_file_upload('fair_data_station/empty.ttl', 'text/turtle')

    assert_no_difference('ExtendedMetadataType.count') do
      with_config_value(:fair_data_station_enabled, true) do
        post :create_from_fair_ds_ttl, params: { emt_fair_ds_ttl_file: file }
      end
    end
    assert_response :success
    assert_select 'p.alert.alert-info', text:/There were no new Extended Metadata Types identified as needing to be created./
    assert_select 'a.btn[href=?]', administer_extended_metadata_types_path, text:'Cancel'
    assert_select 'input.btn[type="submit"][value="Create"]', count: 0
  end

  test 'cannot create from ttl if fair data station disabled' do
    person = FactoryBot.create(:admin)
    assert person.is_admin?
    login_as(person)

    file = fixture_file_upload('fair_data_station/seek-fair-data-station-test-case-irregular.ttl', 'text/turtle')

    assert_no_difference('ExtendedMetadataType.count') do
      with_config_value(:fair_data_station_enabled, false) do
        post :create_from_fair_ds_ttl, params: { emt_fair_ds_ttl_file: file }
      end
    end
    assert_redirected_to :root
    assert_equal 'Fair data station are disabled', flash[:error]
  end


  test 'submit jsons' do
    person_emt = FactoryBot.create(:role_name_extended_metadata_type)
    json1 = file_fixture('extended_metadata_type/valid_simple_emt.json').read
    json2 = file_fixture('extended_metadata_type/valid_emt_with_linked_emt.json').read.gsub('PERSON_EMT_ID', person_emt.id.to_s)
    person = FactoryBot.create(:admin)
    login_as(person)
    assert_difference('ActivityLog.count', 2) do
      assert_difference('ExtendedMetadataType.count', 2) do
        post :submit_jsons, params: { emt_jsons: [json1, json2], emt_titles: ['person new title','family new title'] }
      end
    end
    assert_redirected_to administer_extended_metadata_types_path
    emts = ExtendedMetadataType.last(2)
    activity_logs = ActivityLog.last(2)
    assert_equal emts.sort, activity_logs.collect(&:activity_loggable).sort
    assert_equal ['create'], activity_logs.collect(&:action).uniq
    assert_equal [person.user], activity_logs.collect(&:culprit).uniq
    assert_equal ['person new title', 'family new title'], emts.map(&:title)
    assert_equal '2 Extended Metadata Types successfully created for: person new title(ExtendedMetadata), family new title(Investigation).', flash[:notice]
    assert_nil flash[:error]
  end

  test 'submit jsons - invalid resulting EMT' do
    json1 = file_fixture('extended_metadata_type/invalid_supported_type_emt.json').read
    json2 = file_fixture('extended_metadata_type/valid_simple_emt.json').read
    person = FactoryBot.create(:admin)
    login_as(person)
    assert_difference('ActivityLog.count', 1) do
      assert_difference('ExtendedMetadataType.count', 1) do
        post :submit_jsons, params: { emt_jsons: [json1, json2], emt_titles: ['json1 title', 'json2 title'] }
      end
    end
    assert_redirected_to administer_extended_metadata_types_path
    assert_equal '1 Extended Metadata Type successfully created for: json2 title(ExtendedMetadata).', flash[:notice]
    assert_equal "1 Extended Metadata Type failed to be created: json1 title(Journal) - Supported type 'Journal' is not a valid support type!.", flash[:error]
    assert_equal ExtendedMetadataType.last, ActivityLog.last.activity_loggable
  end

  test 'submit jsons - invalid JSON' do
    json1 = file_fixture('extended_metadata_type/invalid_json.json').read
    json2 = file_fixture('extended_metadata_type/invalid_emt_with_wrong_type.json').read
    json3 = file_fixture('extended_metadata_type/valid_simple_emt.json').read
    person = FactoryBot.create(:admin)
    login_as(person)
    assert_difference('ActivityLog.count', 1) do
      assert_difference('ExtendedMetadataType.count', 1) do
        post :submit_jsons, params: { emt_jsons: [json1, json2, json3], emt_titles: ['json1 title', 'json2 title', 'json3 title'] }
      end
    end
    assert_redirected_to administer_extended_metadata_types_path
    assert_equal '1 Extended Metadata Type successfully created for: json3 title(ExtendedMetadata).', flash[:notice]
    assert_equal "2 Extended Metadata Types failed to be created: Failed to parse JSON, The attribute type 'String1' does not exist..", flash[:error]
    assert_equal ExtendedMetadataType.last, ActivityLog.last.activity_loggable
  end

end

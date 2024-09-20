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
    assert_select 'table tbody tr:not(.emt-partition-title) td', text: emt.title
    assert_select "a[href=?]", new_extended_metadata_type_path, text: 'Create Extended Metadata Type'

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

  test 'upload file successfully' do
    person = FactoryBot.create(:admin)
    login_as(person)

    file = fixture_file_upload('extended_metadata_type/valid_simple_emt.json', 'application/json')
    post :upload_file, params: { emt_json_file: file }

    assert_redirected_to administer_extended_metadata_types_path
    assert_equal 'Your JSON file for extracting the extended metadata type has been uploaded. ', flash[:notice]
  end

  test 'upload file with no file selected' do
    person = FactoryBot.create(:admin)
    login_as(person)

    post :upload_file, params: { emt_json_file: nil }

    assert_redirected_to new_extended_metadata_type_path
    assert_equal 'Please select a file to upload!', flash[:error]
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


end

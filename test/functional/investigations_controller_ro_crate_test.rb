require 'test_helper'

class InvestigationsControllerRoCrateTest < ActionController::TestCase
  tests InvestigationsController

  include AuthenticatedTestHelper

  test 'export ro crate zip for a public investigation' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy))
    study = FactoryBot.create(:study, investigation: investigation, policy: FactoryBot.create(:public_policy))

    get :export_ro_crate, params: { id: investigation.id }

    assert_response :success
    assert_equal 'application/zip', response.media_type
    Zip::File.open_buffer(response.body) do |zip|
      assert zip.find_entry('ro-crate-metadata.json')
      assert zip.find_entry("studies/#{study.id}-#{study.title.parameterize}/")
    end
  end

  test 'ro crate metadata is shown as json without the zip' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy))

    get :ro_crate_metadata, params: { id: investigation.id }

    assert_response :success
    assert_equal 'application/json', response.media_type
    assert_match(/\Ainline; filename="ro-crate-metadata.json"/, response.headers['Content-Disposition'])
    root = JSON.parse(response.body)['@graph'].detect { |e| e['@id'] == './' }
    assert_equal investigation.title, root['name']
  end

  test 'ro crate metadata is the public view even for a logged in viewer' do
    person = FactoryBot.create(:person)
    investigation = FactoryBot.create(:investigation, contributor: person, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:study, investigation: investigation, contributor: person,
                              policy: FactoryBot.create(:private_policy))
    login_as(person)

    get :ro_crate_metadata, params: { id: investigation.id }

    assert_response :success
    assert_equal [], JSON.parse(response.body)['@graph'].detect { |e| e['@id'] == './' }['hasPart']
  end

  test 'export ro crate denied for a hidden investigation' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))

    get :export_ro_crate, params: { id: investigation.id }

    assert_redirected_to investigation_path(investigation)
    assert_match(/not authorized/, flash[:error])
  end

  test 'ro crate metadata denied for a hidden investigation' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))

    get :ro_crate_metadata, params: { id: investigation.id }

    assert_redirected_to investigation_path(investigation)
    assert_match(/not authorized/, flash[:error])
  end

  test 'export buttons shown only for a public investigation' do
    person = FactoryBot.create(:person)
    login_as(person)
    public_policy = FactoryBot.create(:public_policy)
    private_policy = FactoryBot.create(:private_policy)
    public_investigation = FactoryBot.create(:investigation, contributor: person, policy: public_policy)
    private_investigation = FactoryBot.create(:investigation, contributor: person, policy: private_policy)

    get :show, params: { id: public_investigation }
    assert_select 'a', text: 'Export RO-Crate', count: 1
    assert_select 'a[href=?]', ro_crate_metadata_investigation_path(public_investigation), count: 1

    get :show, params: { id: private_investigation }
    assert_select 'a', text: 'Export RO-Crate', count: 0
    assert_select 'a[href=?]', ro_crate_metadata_investigation_path(private_investigation), count: 0
  end
end

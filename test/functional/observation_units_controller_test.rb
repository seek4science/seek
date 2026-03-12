require 'test_helper'
require 'minitest/mock'

class ObservationUnitsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases
  include RdfTestCases

  def rdf_test_object
    FactoryBot.create(:max_observation_unit)
  end

  test 'show' do
    unit = FactoryBot.create(:max_observation_unit)
    get :show, params: { id: unit.id }
    assert_response :success
    assert_select 'div.contribution-header h1', text:/#{unit.title}/
    assert_select 'div#overview' do
      assert_select 'div#description', text:/#{unit.description}/
      assert_select 'div#extended-metadata div', text:/Extended Metadata \(simple obs unit extended metadata type\)/
    end
  end

  test 'index' do
    unit = FactoryBot.create(:max_observation_unit)
    get :index
    assert_response :success
    assert_select 'div.list_item', count: 1 do
      assert_select 'div.list_item_title', text:/#{unit.title}/
    end
  end

  test 'edit' do
    unit = FactoryBot.create(:max_observation_unit)
    login_as(unit.contributor)
    get :edit, params: { id: unit.id}
    assert_response :success
  end

  test 'manage' do
    unit = FactoryBot.create(:max_observation_unit)
    login_as(unit.contributor)
    get :manage, params: { id: unit.id}
    assert_response :success
  end

  test 'manage update' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    other_creator = FactoryBot.create(:person)

    obs_unit = FactoryBot.create(:observation_unit, contributor:person, policy:FactoryBot.create(:private_policy))

    login_as(person)
    assert obs_unit.can_manage?

    patch :manage_update, params: {id: obs_unit,
                                   observation_unit: {
                                     creator_ids: [other_creator.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to obs_unit

    obs_unit.reload
    assert_equal [other_creator], obs_unit.creators
    assert_equal Policy::VISIBLE, obs_unit.policy.access_type
    assert_equal 1, obs_unit.policy.permissions.count
    assert_equal other_person, obs_unit.policy.permissions.first.contributor
    assert_equal Policy::MANAGING, obs_unit.policy.permissions.first.access_type
  end

  test 'update' do
    obs_unit = FactoryBot.create(:observation_unit)
    other_study = FactoryBot.create(:study, contributor:obs_unit.contributor)
    emt = FactoryBot.create(:simple_observation_unit_extended_metadata_type)
    datafile = FactoryBot.create(:data_file, contributor: obs_unit.contributor)
    sample = FactoryBot.create(:sample, contributor: obs_unit.contributor)
    login_as(obs_unit.contributor)

    patch :update, params: { id: obs_unit,
                             observation_unit:{
                               title: 'updated title',
                               description: 'updated description',
                               data_file_ids: [datafile.id],
                               sample_ids: [sample.id],
                               study_id: other_study.id,
                               extended_metadata_attributes: {
                                 extended_metadata_type_id: emt.id,
                                 data: {
                                   name: 'updated name',
                                   strain: 'updated strain'
                                 }
                               }
                             },
                             tag_list:'fish, soup',
    }

    assert_redirected_to obs_unit

    obs_unit.reload
    assert_equal 'updated title', obs_unit.title
    assert_equal 'updated description', obs_unit.description
    assert_equal emt, obs_unit.extended_metadata.extended_metadata_type
    assert_equal 'updated name', obs_unit.extended_metadata.get_attribute_value('name')
    assert_equal 'updated strain', obs_unit.extended_metadata.get_attribute_value('strain')
    assert_equal %w[fish soup], obs_unit.tags.sort
    assert_equal [datafile], obs_unit.data_files
    assert_equal [sample], obs_unit.samples
    assert_equal other_study, obs_unit.study
  end

  test 'new' do
    person = FactoryBot.create(:person)
    FactoryBot.create(:study, contributor: person)
    login_as(person)
    get :new
    assert_response :success
  end

  test 'create' do
    emt = FactoryBot.create(:simple_observation_unit_extended_metadata_type)
    contributor = FactoryBot.create(:person)
    study = FactoryBot.create(:study, contributor: contributor)
    datafile = FactoryBot.create(:data_file, contributor: contributor)
    sample = FactoryBot.create(:sample, contributor: contributor)
    other_person = FactoryBot.create(:person)
    creator = FactoryBot.create(:person)
    login_as(contributor)

    post :create, params: {  observation_unit:{
                               title: 'new title',
                               description: 'new description',
                               creator_ids: [creator.id],
                               data_file_ids: [datafile.id],
                               sample_ids: [sample.id],
                               study_id: study,
                               extended_metadata_attributes: {
                                 extended_metadata_type_id: emt.id,
                                 data: {
                                   name: 'new name',
                                   strain: 'new strain'
                                 }
                               }
                             },
                             tag_list:'fish, soup',
                             policy_attributes: {
                               access_type: Policy::VISIBLE,
                               permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}
                               }
                             }
    }

    assert_redirected_to obs_unit=assigns(:observation_unit)
    assert_equal 'new title', obs_unit.title
    assert_equal 'new description', obs_unit.description
    assert_equal emt, obs_unit.extended_metadata.extended_metadata_type
    assert_equal 'new name', obs_unit.extended_metadata.get_attribute_value('name')
    assert_equal 'new strain', obs_unit.extended_metadata.get_attribute_value('strain')
    assert_equal %w[fish soup], obs_unit.tags.sort
    assert_equal contributor, obs_unit.contributor
    assert_equal study.projects, obs_unit.projects
    assert_equal [creator], obs_unit.creators
    assert_equal [datafile], obs_unit.data_files
    assert_equal [sample], obs_unit.samples
    assert_equal Policy::VISIBLE, obs_unit.policy.access_type
    assert_equal 1,obs_unit.policy.permissions.count
    assert_equal other_person, obs_unit.policy.permissions.first.contributor
    assert_equal Policy::MANAGING, obs_unit.policy.permissions.first.access_type
  end

  test 'no access if observation units disabled' do
    unit = FactoryBot.create(:max_observation_unit)
    login_as(unit.contributor)
    with_config_value(:observation_units_enabled, false) do
      get :show, params: { id: unit.id }
      assert_redirected_to :root
      refute_nil flash[:error]

      get :index
      assert_redirected_to :root
      refute_nil flash[:error]

      get :new
      assert_redirected_to :root
      refute_nil flash[:error]

      get :edit, params: { id: unit.id }
      assert_redirected_to :root
      refute_nil flash[:error]

      get :manage, params: { id: unit.id }
      assert_redirected_to :root
      refute_nil flash[:error]

      patch :update, params: { id: unit.id,
                               observation_unit:{
                                 title: 'updated title',
                               }}
      assert_redirected_to :root
      refute_nil flash[:error]

    end
  end

  test 'preview observation unit' do
    person = FactoryBot.create(:person)
    login_as(person)
    obs_unit = FactoryBot.create(:observation_unit, title: 'preview obs unit', policy: FactoryBot.create(:public_policy), contributor:person)
    get :preview, xhr: true, params: { id: obs_unit.id }
    assert_response :success
    assert_includes response.body, "<a href=\\\"/observation_units/#{obs_unit.id}\\\">preview obs unit<\\/a>"
  end

end
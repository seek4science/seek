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
    assert_select 'form.edit_observation_unit' do
      assert_select 'div#project-selector', count: 0
    end
  end

  test 'manage' do
    unit = FactoryBot.create(:max_observation_unit)
    login_as(unit.contributor)
    get :manage, params: { id: unit.id}
    assert_response :success
    assert_select 'form.edit_observation_unit' do
      assert_select 'div#project-selector'
    end
  end

  test 'manage update' do
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj1)
    other_person = FactoryBot.create(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!
    other_creator = FactoryBot.create(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    obs_unit = FactoryBot.create(:observation_unit, contributor:person, projects:[proj1], policy:FactoryBot.create(:private_policy))

    login_as(person)
    assert obs_unit.can_manage?

    patch :manage_update, params: {id: obs_unit,
                                   observation_unit: {
                                     creator_ids: [other_creator.id],
                                     project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to obs_unit

    obs_unit.reload
    assert_equal [proj1,proj2],obs_unit.projects.sort_by(&:id)
    assert_equal [other_creator],obs_unit.creators
    assert_equal Policy::VISIBLE,obs_unit.policy.access_type
    assert_equal 1,obs_unit.policy.permissions.count
    assert_equal other_person,obs_unit.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,obs_unit.policy.permissions.first.access_type
  end

  test 'update' do
    obs_unit = FactoryBot.create(:observation_unit)
    emt = FactoryBot.create(:simple_observation_unit_extended_metadata_type)
    login_as(obs_unit.contributor)

    patch :update, params: { id: obs_unit,
                             observation_unit:{
                               title: 'updated title',
                               description: 'updated description',
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
  end

  test 'new' do
    person = FactoryBot.create(:person)
    FactoryBot.create(:study, contributor: person)
    login_as(person)
    get :new
    assert_response :success
    assert_select 'form.new_observation_unit' do
      assert_select 'div#project-selector'
    end
  end

  test 'create' do
    emt = FactoryBot.create(:simple_observation_unit_extended_metadata_type)
    contributor = FactoryBot.create(:person)
    study = FactoryBot.create(:study, contributor: contributor)
    project = contributor.projects.first
    other_person = FactoryBot.create(:person)
    creator = FactoryBot.create(:person)
    login_as(contributor)

    post :create, params: {  observation_unit:{
                               title: 'new title',
                               description: 'new description',
                               creator_ids: [creator.id],
                               project_ids: [project],
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
    assert_equal [project],obs_unit.projects.sort_by(&:id)
    assert_equal [creator],obs_unit.creators
    assert_equal Policy::VISIBLE,obs_unit.policy.access_type
    assert_equal 1,obs_unit.policy.permissions.count
    assert_equal other_person,obs_unit.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,obs_unit.policy.permissions.first.access_type
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

end
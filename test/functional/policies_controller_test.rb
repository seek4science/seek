require 'test_helper'

class PoliciesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  def setup
    login_as(Factory(:person).user)
  end

  test 'should show the preview permission when choosing public scope' do
    post :preview_permissions, params: { policy_attributes: { access_type: Policy::ACCESSIBLE }, resource_name: 'data_file' }

    assert_response :success
    assert_select 'p.public', text: "All visitors can #{Policy.get_access_type_wording(2, 'data_file'.camelize.constantize.new).downcase}.", count: 1
  end

  test 'should show the preview permission when choosing private scope' do
    post :preview_permissions, params: { policy_attributes: { access_type: Policy::NO_ACCESS }, resource_name: 'data_file' }

    assert_response :success
    assert_select 'p.private', text: "This #{I18n.t('data_file')} is hidden from public view.", count: 1
  end

  test 'should show the preview permission when custom the permissions for Person, Project and FavouriteGroup' do
    user = Factory(:user)
    login_as(user)

    person = Factory(:person_in_project)
    favorite_group = Factory(:favourite_group, user: user)
    project = Factory(:project)

    post :preview_permissions, params: { policy_attributes: {
      access_type: Policy::NO_ACCESS,
      permissions_attributes: {
        # create a person and set access_type to Policy::MANAGING
        '1' => { contributor_type: 'Person', contributor_id: person.id, access_type: Policy::MANAGING },
        # create a favourite group and members, set access_type to Policy::EDITING
        '2' => { contributor_type: 'FavouriteGroup', contributor_id: favorite_group.id, access_type: Policy::DETERMINED_BY_GROUP },
        # create a project and members and set access_type to Policy::ACCESSIBLE
        '3' => { contributor_type: 'Project', contributor_id: project.id, access_type: Policy::ACCESSIBLE }
      }
    }, resource_name: 'data_file' }

    assert_response :success
    assert_select 'h3', text: 'Additionally...', count: 1

    assert_select 'div.access-type-manage li', text: person.name, count: 1
    assert_select 'div.access-type-download li', text: "Members of #{project.title}", count: 1
  end

  test 'should show the correct manager(contributor) when updating a study' do
    study = Factory(:study)
    contributor = study.contributor
    post :preview_permissions, params: { policy_attributes: { access_type: Policy::VISIBLE }, resource_id: study.id, resource_name: 'study' }

    assert_select 'div.access-type-manage li', text: "#{contributor.name}", count: 1
  end

  test 'should show notice message when an item is requested to be published' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.map(&:id))
    login_as(sop.contributor)
    post :preview_permissions, params: { policy_attributes: projects_policy(Policy::VISIBLE, [gatekeeper.projects.first], Policy::ACCESSIBLE), resource_name: 'sop', resource_id: sop.id, project_ids: gatekeeper.projects.first.id.to_s }

    assert_select '#preview_permissions div.alert', text: "An email will be sent to the #{I18n.t('asset_gatekeeper').pluralize.downcase} of the #{I18n.t('project').pluralize} associated with this #{I18n.t('sop')} to ask for publishing approval. This #{I18n.t('sop')} will not be published until one of the #{I18n.t('asset_gatekeeper').pluralize.downcase} has granted approval.", count: 1
  end

  test 'should show notice message when an item is requested to be published and the request was alread sent by this user' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.map(&:id))
    login_as(sop.contributor)
    ResourcePublishLog.add_log ResourcePublishLog::WAITING_FOR_APPROVAL, sop
    post :preview_permissions, params: { policy_attributes: { access_type: Policy::VISIBLE }, resource_name: 'sop', resource_id: sop.id, project_ids: gatekeeper.projects.first.id.to_s }

    assert_select '#preview_permissions div.alert', text: "You requested the publishing approval from one of the #{I18n.t('asset_gatekeeper').pluralize.downcase } of the #{I18n.t('project').pluralize} associated with this #{I18n.t('sop')}, and it is waiting for the decision. This #{I18n.t('sop')} will not be published until one of the #{I18n.t('asset_gatekeeper').pluralize.downcase } has granted approval.", count: 1
  end

  test 'should not show notice message when an item can be published right away' do
    post :preview_permissions, params: { policy_attributes: { access_type: Policy::VISIBLE }, resource_name: 'sop', project_ids: Factory(:project).id.to_s }

    assert_select '#preview_permissions div.alert', text: "An email will be sent to the #{I18n.t('asset_gatekeeper').pluralize.downcase} of the  #{I18n.t('project').pluralize} associated with this #{I18n.t('sop')} to ask for publishing approval. This #{I18n.t('sop')} will not be published until one of the #{I18n.t('asset_gatekeeper').pluralize.downcase } has granted approval.", count: 0
  end

  test 'when creating an item, can not publish the item if associate to it the project which has gatekeeper' do
    gatekeeper = Factory(:asset_gatekeeper)
    a_person = Factory(:person)
    sop = Sop.new

    login_as(a_person.user)
    assert sop.can_manage?

    updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(sop, gatekeeper.projects.first)
    assert !updated_can_publish_immediately
  end

  test 'when creating an item, can publish the item if associate to it the project which has no gatekeeper' do
    a_person = Factory(:person)
    sop = Sop.new

    login_as(a_person.user)
    assert sop.can_manage?

    updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(sop, Factory(:project))
    assert updated_can_publish_immediately
  end

  test 'when updating an item, can not publish the item if associate to it the project which has gatekeeper' do
    as_not_virtualliver do
      gatekeeper = Factory(:asset_gatekeeper)
      a_person = Factory(:person)
      item = Factory(:sop, policy: Factory(:policy))
      Factory(:permission, contributor: a_person, access_type: Policy::MANAGING, policy: item.policy)
      item.reload

      login_as(a_person.user)
      assert item.can_manage?

      updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(item, gatekeeper.projects.first)
      assert !updated_can_publish_immediately
    end
  end

  test 'when updating an item, can publish the item if dissociate to it the project which has gatekeeper' do
    as_not_virtualliver do
      gatekeeper = Factory(:asset_gatekeeper)
      a_person = Factory(:person)
      item = Factory(:sop, policy: Factory(:policy), project_ids: gatekeeper.projects.collect(&:id))
      Factory(:permission, contributor: a_person, access_type: Policy::MANAGING, policy: item.policy)
      item.reload

      login_as(a_person.user)
      assert item.can_manage?

      updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(item, Factory(:project))
      assert updated_can_publish_immediately
    end
  end

  test 'can publish assay without study' do
    a_person = Factory(:person)
    assay = Assay.new

    login_as(a_person.user)
    assert assay.can_manage?

    updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(assay, [])
    assert updated_can_publish_immediately
  end

  test 'can not publish assay having project with gatekeeper' do
    as_not_virtualliver do
      gatekeeper = Factory(:asset_gatekeeper)
      refute_empty gatekeeper.projects
      a_person = Factory(:person, project: gatekeeper.projects.first)
      inv = Factory(:investigation, contributor: gatekeeper)
      study = Factory(:study, investigation: inv, contributor: gatekeeper)
      assay = Assay.new
      assay.study = study

      assert_equal assay.projects, gatekeeper.projects
      login_as(a_person.user)
      assert assay.can_manage?

      # FIXME: can't test controller this way properly as it doesn't setup the @request and session properly
      updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(assay, assay.study.projects)
      refute updated_can_publish_immediately
    end
  end

  test 'always can publish for the published item' do
    gatekeeper = Factory(:asset_gatekeeper)
    a_person = Factory(:person)
    login_as(gatekeeper.user)
    item = Factory(:sop, contributor: gatekeeper, policy: Factory(:public_policy), project_ids: gatekeeper.projects.collect(&:id))
    Factory(:permission, contributor: a_person, access_type: Policy::MANAGING, policy: item.policy)
    item.reload

    login_as(a_person.user)
    assert item.can_manage?

    updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(item, gatekeeper.projects.first)
    assert updated_can_publish_immediately
  end

  test 'should show the preview permission for resource without projects' do
    post :preview_permissions, params: { policy_attributes: { access_type: Policy::VISIBLE }, project_access_type: Policy::ACCESSIBLE, project_ids: '0', resource_name: 'study' }
    assert_response :success

    post :preview_permissions, params: { policy_attributes: { access_type: Policy::VISIBLE }, project_access_type: Policy::ACCESSIBLE, project_ids: '0', resource_name: 'assay' }
    assert_response :success

    post :preview_permissions, params: { policy_attributes: { access_type: Policy::VISIBLE }, project_access_type: Policy::ACCESSIBLE, project_ids: '0', resource_name: 'sop' }
    assert_response :success
  end

  test 'additional permissions and privilege text for preview permission' do
    # no additional text
    post :preview_permissions, params: { policy_attributes: { access_type: Policy::NO_ACCESS }, resource_name: 'assay' }

    # with additional text for permissions
    project = Factory(:project)
    post :preview_permissions, params: { policy_attributes: projects_policy(Policy::VISIBLE, [project.id], Policy::ACCESSIBLE), resource_name: 'data_file', project_ids: project.id }

    # with additional text for privileged people
    asset_manager = Factory(:asset_housekeeper)
    post :preview_permissions, params: { policy_attributes: projects_policy(Policy::NO_ACCESS, [asset_manager.projects.first], Policy::ACCESSIBLE), resource_name: 'data_file', project_ids: asset_manager.projects.first.id }

    # with additional text for both permissions and privileged people
    asset_manager = Factory(:asset_housekeeper)
    post :preview_permissions, params: { policy_attributes: projects_policy(Policy::VISIBLE, [asset_manager.projects.first], Policy::ACCESSIBLE), resource_name: 'data_file', project_ids: asset_manager.projects.first.id }
  end

  test 'should display download permissions as view for non-downloadable resource in permission preview' do
    person = Factory(:person_in_project)
    project = Factory(:project)

    post :preview_permissions, params: { policy_attributes: {
        access_type: Policy::NO_ACCESS,
        permissions_attributes: {
            '1' => { contributor_type: 'Person', contributor_id: person.id, access_type: Policy::VISIBLE },
            '2' => { contributor_type: 'Project', contributor_id: project.id, access_type: Policy::ACCESSIBLE }
        }
    }, resource_name: 'study', project_ids: project.id }

    assert_response :success

    assert_select 'p.private', text: "This #{I18n.t('study')} is hidden from public view.", count: 1
    assert_select 'div.access-type-view li', text: "Members of #{project.title}", count: 1
    assert_select 'div.access-type-view li', text: person.name, count: 1
  end
end

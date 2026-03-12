require 'test_helper'

class FairDataStationUploadTest < ActiveSupport::TestCase
  test 'validate' do
    person = FactoryBot.create(:person)
    item = FairDataStationUpload.new(contributor: person, project: person.projects.first,
                                     content_blob: FactoryBot.create(:content_blob), purpose: :import)

    assert item.valid?

    item.contributor = nil
    refute item.valid?
    item.contributor = person
    assert item.valid?

    # import purpose needs project

    item.project = nil
    refute item.valid?
    item.project = FactoryBot.create(:project)
    refute item.valid?
    item.project = person.projects.first
    assert item.valid?

    item.purpose = nil
    refute item.valid?
    item.purpose = :import
    assert item.valid?

    item.content_blob = nil
    refute item.valid?

    # update purpose needs investigation that can_manage?

    item = FairDataStationUpload.new(contributor: person,
                                     content_blob: FactoryBot.create(:content_blob), purpose: :update)

    assert_nil item.investigation
    refute item.valid?

    item.investigation = FactoryBot.create(:investigation, policy: FactoryBot.build(:private_policy))
    refute item.investigation.can_manage?(item.contributor)
    refute item.valid?
    item.investigation = FactoryBot.create(:investigation, policy: FactoryBot.build(:editing_public_policy))
    refute item.investigation.can_manage?(item.contributor)
    refute item.valid?
    item.investigation = FactoryBot.create(:investigation, contributor: item.contributor)
    assert item.investigation.can_manage?(item.contributor)
    assert item.valid?
  end

  test 'for_project_and_contributor scope' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    person2 = FactoryBot.create(:person)
    project2 = person2.projects.first
    up1 = FactoryBot.create(:fair_data_station_upload, project: project, contributor: person)
    up2 = FactoryBot.create(:fair_data_station_upload, project: project2, contributor: person2)
    FactoryBot.create(:fair_data_station_upload)

    assert_equal [up1], FairDataStationUpload.for_project_and_contributor(project, person)
    assert_empty FairDataStationUpload.for_project_and_contributor(project2, person)
    assert_empty FairDataStationUpload.for_project_and_contributor(project, person2)
    assert_equal [up2], FairDataStationUpload.for_project_and_contributor(project2, person2)
  end

  test 'matching imports in progress' do
    person = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    project = person.projects.first
    project2 = FactoryBot.create(:project)
    person.add_to_project_and_institution(project2, person.institutions.first)
    person2.add_to_project_and_institution(project, person2.institutions.first)
    upload = FactoryBot.create(:fair_data_station_upload, contributor: person, project: project,
                                                          investigation_external_identifier: 'test-id', purpose: :import)
    upload.import_task.update_attribute(:status, Task::STATUS_WAITING)
    upload2 = FactoryBot.create(:fair_data_station_upload, contributor: person, project: project,
                                                           investigation_external_identifier: 'test-id', purpose: :import)
    upload2.import_task.update_attribute(:status, Task::STATUS_QUEUED)
    upload3 = FactoryBot.create(:fair_data_station_upload, contributor: person, project: project,
                                                           investigation_external_identifier: 'test-id', purpose: :import)
    upload3.import_task.update_attribute(:status, Task::STATUS_ACTIVE)
    # same project, different person
    upload4 = FactoryBot.create(:fair_data_station_upload, contributor: person2, project: project,
                                                           investigation_external_identifier: 'test-id', purpose: :import)
    upload4.import_task.update_attribute(:status, Task::STATUS_QUEUED)
    # different identifier
    FactoryBot.create(:fair_data_station_upload, contributor: person, project: project, investigation_external_identifier: 'another-id', purpose: :import).import_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )
    # different purpose
    investigation = FactoryBot.create(:investigation, contributor: person, projects: [project])
    FactoryBot.create(:fair_data_station_upload, contributor: person, project: project, investigation: investigation, investigation_external_identifier: 'test-id', purpose: :update).import_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )
    # different project
    FactoryBot.create(:fair_data_station_upload, contributor: person, project: project2, investigation_external_identifier: 'test-id', purpose: :import).import_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )
    # complete
    FactoryBot.create(:fair_data_station_upload, contributor: person, project: project, investigation_external_identifier: 'test-id', purpose: :import).import_task.update_attribute(
      :status, Task::STATUS_DONE
    )
    # cancelled
    FactoryBot.create(:fair_data_station_upload, contributor: person, project: project, investigation_external_identifier: 'test-id', purpose: :import).import_task.update_attribute(
      :status, Task::STATUS_CANCELLED
    )
    # failed
    FactoryBot.create(:fair_data_station_upload, contributor: person, project: project, investigation_external_identifier: 'test-id', purpose: :import).import_task.update_attribute(
      :status, Task::STATUS_FAILED
    )

    matches = FairDataStationUpload.matching_imports_in_progress(project, 'test-id')
    assert_equal [upload, upload2, upload3, upload4].sort, matches.sort
  end

  test 'matching updates in progress' do
    investigation = FactoryBot.create(:investigation, external_identifier: 'test-id')
    person = investigation.contributor
    investigation2 = FactoryBot.create(:investigation, external_identifier: 'test-id', contributor: person,
                                                       projects: [FactoryBot.create(:project)])
    project = investigation.projects.first

    upload = FactoryBot.create(:update_fair_data_station_upload, contributor: person,
                                                                 investigation_external_identifier: 'test-id', investigation: investigation)
    upload.update_task.update_attribute(:status, Task::STATUS_WAITING)
    upload2 = FactoryBot.create(:update_fair_data_station_upload, contributor: person,
                                                                  investigation_external_identifier: 'test-id', investigation: investigation)
    upload2.update_task.update_attribute(:status, Task::STATUS_QUEUED)
    upload3 = FactoryBot.create(:update_fair_data_station_upload, contributor: person,
                                                                  investigation_external_identifier: 'test-id', investigation: investigation)
    upload3.update_task.update_attribute(:status, Task::STATUS_ACTIVE)

    # different identifier
    FactoryBot.create(:update_fair_data_station_upload, contributor: person, investigation_external_identifier: 'another-id', investigation: investigation).update_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )
    # different purpose
    FactoryBot.create(:fair_data_station_upload, contributor: person, investigation_external_identifier: 'test-id', project: project, investigation: investigation, purpose: :import).update_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )
    # different investigation
    FactoryBot.create(:update_fair_data_station_upload, contributor: person, investigation_external_identifier: 'test-id', investigation: investigation2).update_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )
    # complete
    FactoryBot.create(:update_fair_data_station_upload, contributor: person, investigation_external_identifier: 'test-id', investigation: investigation).update_task.update_attribute(
      :status, Task::STATUS_DONE
    )
    # cancelled
    FactoryBot.create(:update_fair_data_station_upload, contributor: person, investigation_external_identifier: 'test-id', investigation: investigation).update_task.update_attribute(
      :status, Task::STATUS_CANCELLED
    )
    # failed
    FactoryBot.create(:update_fair_data_station_upload, contributor: person, investigation_external_identifier: 'test-id', investigation: investigation).update_task.update_attribute(
      :status, Task::STATUS_FAILED
    )

    matches = FairDataStationUpload.matching_updates_in_progress(investigation, 'test-id')
    assert_equal [upload, upload2, upload3].sort, matches.sort
  end

  test 'clean up after investigation destroyed' do
    investigation = FactoryBot.create(:investigation)
    contributor = investigation.contributor
    project = investigation.projects.first
    upload1 = FactoryBot.create(:fair_data_station_upload, investigation: investigation, project: project, contributor: contributor)
    upload2 = FactoryBot.create(:update_fair_data_station_upload, investigation: investigation, project: project, contributor: contributor)
    blob1 = upload1.content_blob
    blob2 = upload2.content_blob
    refute blob1.deleted?
    refute blob2.deleted?
    assert_equal [upload1, upload2], investigation.fair_data_station_uploads
    User.with_current_user(contributor.user) do
      assert_difference('Investigation.count', -1) do
        assert_difference('Policy.count', -2) do
          assert_difference('FairDataStationUpload.count', -2) do
            assert_no_difference('ContentBlob.count') do
              investigation.destroy!
            end
          end
        end
      end
    end
    # blobs are not deleted immediately, but marked for deletion to be cleaned up by a job
    blob1.reload
    blob2.reload
    assert blob1.deleted?
    assert blob2.deleted?
  end
end

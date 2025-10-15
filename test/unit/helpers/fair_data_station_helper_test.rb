require 'test_helper'

class FairDataStationHelperTest < ActionView::TestCase
  test 'show_update_from_fair_data_station_button?' do
    person = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)

    inv = FactoryBot.create(:investigation, external_identifier: 'test-inv-identifier', contributor: person)
    inv2 = FactoryBot.create(:investigation, external_identifier: '', contributor: person)

    with_config_value(:fair_data_station_enabled, true) do
      User.with_current_user(person.user) do
        assert show_update_from_fair_data_station_button?(inv)
        refute show_update_from_fair_data_station_button?(inv2)
      end

      User.with_current_user(person2.user) do
        refute show_update_from_fair_data_station_button?(inv)
        refute show_update_from_fair_data_station_button?(inv2)
      end
    end

    with_config_value(:fair_data_station_enabled, false) do
      User.with_current_user(person.user) do
        refute show_update_from_fair_data_station_button?(inv)
      end
    end
  end

  test 'fair_data_station_imports_to_show' do
    upload1 = FactoryBot.create(:fair_data_station_upload)
    project = upload1.project
    contributor = upload1.contributor
    upload1.import_task.update_attribute(:status, Task::STATUS_QUEUED)
    upload2 = FactoryBot.create(:fair_data_station_upload, project: project, contributor: contributor)
    upload2.import_task.update_attribute(:status, Task::STATUS_ACTIVE)
    upload3 = FactoryBot.create(:fair_data_station_upload, project: project, contributor: contributor)
    upload3.import_task.update_attribute(:status, Task::STATUS_DONE)
    upload4 = FactoryBot.create(:fair_data_station_upload, project: project, contributor: contributor)
    upload4.import_task.update_attribute(:status, Task::STATUS_FAILED)

    # show status is false
    FactoryBot.create(:fair_data_station_upload, project: project, contributor: contributor, show_status: false).import_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )

    # different contributor
    other_person = FactoryBot.create(:person)
    other_person.add_to_project_and_institution(project, other_person.institutions.first)
    other_person.save!
    other_person.reload
    FactoryBot.create(:fair_data_station_upload, project: project, contributor: other_person).import_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )

    # different project
    other_project = FactoryBot.create(:project)
    contributor.add_to_project_and_institution(other_project, contributor.institutions.first)
    contributor.save!
    contributor.reload
    FactoryBot.create(:fair_data_station_upload, project: other_project, contributor: contributor).import_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )

    # wrong purpose
    investigation = FactoryBot.create(:investigation, contributor: contributor, projects: [project])
    FactoryBot.create(:fair_data_station_upload, project: project, contributor: contributor, investigation: investigation, purpose: :update).import_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )

    # wrong task status
    FactoryBot.create(:fair_data_station_upload, project: project, contributor: contributor).import_task.update_attribute(
      :status, Task::STATUS_WAITING
    )
    FactoryBot.create(:fair_data_station_upload, project: project, contributor: contributor).import_task.update_attribute(
      :status, Task::STATUS_CANCELLED
    )

    # in reverse order, most recent first
    assert_equal [upload4, upload3, upload2, upload1], fair_data_station_imports_to_show(project, contributor)
  end

  test 'fair_data_station_investigation_updates_to_show' do
    upload1 = FactoryBot.create(:update_fair_data_station_upload)
    investigation = upload1.investigation
    contributor = upload1.contributor
    upload1.update_task.update_attribute(:status, Task::STATUS_QUEUED)
    upload2 = FactoryBot.create(:update_fair_data_station_upload, contributor: contributor,
                                                                  investigation: investigation)
    upload2.update_task.update_attribute(:status, Task::STATUS_ACTIVE)
    upload3 = FactoryBot.create(:update_fair_data_station_upload, contributor: contributor,
                                                                  investigation: investigation)
    upload3.update_task.update_attribute(:status, Task::STATUS_DONE)
    upload4 = FactoryBot.create(:update_fair_data_station_upload, contributor: contributor,
                                                                  investigation: investigation)
    upload4.update_task.update_attribute(:status, Task::STATUS_FAILED)

    # show status is false
    FactoryBot.create(:update_fair_data_station_upload, contributor: contributor, investigation: investigation, show_status: false).update_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )

    # different contributor
    other_person = FactoryBot.create(:person)
    investigation.policy.permissions.create(access_type: Policy::MANAGING, contributor: other_person)
    assert investigation.can_manage?(other_person)
    FactoryBot.create(:update_fair_data_station_upload, investigation: investigation, contributor: other_person).update_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )

    # different investigation
    other_inv = FactoryBot.create(:investigation, contributor: contributor)
    FactoryBot.create(:update_fair_data_station_upload, contributor: contributor, investigation: other_inv).update_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )

    # wrong purpose
    FactoryBot.create(:update_fair_data_station_upload, contributor: contributor, project: investigation.projects.first, investigation: investigation, purpose: :import).update_task.update_attribute(
      :status, Task::STATUS_QUEUED
    )

    # wrong task status
    FactoryBot.create(:update_fair_data_station_upload, contributor: contributor, investigation: investigation).update_task.update_attribute(
      :status, Task::STATUS_WAITING
    )
    FactoryBot.create(:update_fair_data_station_upload, contributor: contributor, investigation: investigation).update_task.update_attribute(
      :status, Task::STATUS_CANCELLED
    )

    # in reverse order, most recent first
    assert_equal [upload4, upload3, upload2, upload1],
                 fair_data_station_investigation_updates_to_show(investigation, contributor)
  end

  test 'fair_data_station_investigation_updates_in_progress?' do
    upload = FactoryBot.create(:update_fair_data_station_upload)
    contributor = upload.contributor
    investigation = upload.investigation
    project = upload.contributor.projects.first
    upload.update_task.update_attribute(:status, Task::STATUS_QUEUED)

    assert fair_data_station_investigation_updates_in_progress?(investigation, contributor)

    upload.update_task.update_attribute(:status, Task::STATUS_ACTIVE)
    assert fair_data_station_investigation_updates_in_progress?(investigation, contributor)

    upload.update_task.update_attribute(:status, Task::STATUS_DONE)
    refute fair_data_station_investigation_updates_in_progress?(investigation, contributor)

    upload.update_task.update_attribute(:status, Task::STATUS_FAILED)
    refute fair_data_station_investigation_updates_in_progress?(investigation, contributor)

    upload.update_task.update_attribute(:status, Task::STATUS_CANCELLED)
    refute fair_data_station_investigation_updates_in_progress?(investigation, contributor)

    upload2 = FactoryBot.create(:update_fair_data_station_upload, contributor: contributor,
                                                                  investigation: investigation)
    upload2.update_task.update_attribute(:status, Task::STATUS_ACTIVE)
    assert fair_data_station_investigation_updates_in_progress?(investigation, contributor)

    upload2.investigation = FactoryBot.create(:investigation, contributor: contributor, projects: [project])
    upload2.save!
    refute fair_data_station_investigation_updates_in_progress?(investigation, contributor)
  end
end

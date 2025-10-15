require 'test_helper'

class FairDataStationUpdateJobTest < ActiveSupport::TestCase
  test 'queue' do
    upload_record = FactoryBot.create :update_fair_data_station_upload
    assert_enqueued_jobs(1, only: FairDataStationUpdateJob) do
      FairDataStationUpdateJob.new(upload_record).queue_job
    end
    upload_record.reload
    assert upload_record.update_task.pending?
  end

  test 'perform' do
    investigation = setup_test_case_investigation
    person = investigation.contributor

    upload = FactoryBot.create(:update_fair_data_station_upload, contributor: person, investigation: investigation)
    assert_no_difference('Investigation.count') do
      assert_difference('Study.count', 1) do
        assert_difference('ObservationUnit.count', 1) do
          assert_difference('Sample.count', 1) do
            assert_difference('Assay.count', 1) do
              assert_difference('ActivityLog.count', 18) do
                FairDataStationUpdateJob.perform_now(upload)
              end
            end
          end
        end
      end
    end
  end

  test 'record errors' do
    investigation = setup_test_case_investigation
    person = investigation.contributor

    upload = FactoryBot.create(:invalid_update_fair_data_station_upload, contributor: person,
                                                                         investigation: investigation)
    assert_no_difference('Investigation.count') do
      assert_no_difference('Study.count') do
        assert_no_difference('ObservationUnit.count') do
          assert_no_difference('Sample.count') do
            assert_no_difference('Assay.count') do
              assert_no_difference('ActivityLog.count') do
                FairDataStationUpdateJob.perform_now(upload)
              end
            end
          end
        end
      end
    end

    assert_equal 'test study 2', Study.by_external_identifier('seek-test-study-2', investigation.projects).title
    assert_equal 'test seek sample 1', Sample.by_external_identifier('seek-test-sample-1', investigation.projects).title

    # this may have changed in an update before the error, so this checks the transaction is behaving correctly and rolling back
    assert_equal 'test obs unit 1',
                 ObservationUnit.by_external_identifier('seek-test-obs-unit-1', investigation.projects).title

    upload.reload
    assert upload.update_task.failed?
    assert_equal "ActiveRecord::RecordInvalid: Validation failed: Title can't be blank, Title is required",
                 upload.update_task.error_message
    assert_match(/block in _perform_job/, upload.update_task.exception)
  end

  test 'no sample type recorded' do
    investigation = setup_test_case_investigation
    person = investigation.contributor
    # make the sample type hidden
    disable_authorization_checks do
      sample_type = SampleType.last
      sample_type.policy.update_column(:access_type, Policy::NO_ACCESS)
      refute sample_type.can_view?(person)
    end
    upload = FactoryBot.create(:update_fair_data_station_upload, contributor: person,
                               investigation: investigation)
    assert_no_difference('Investigation.count') do
      assert_no_difference('Study.count') do
        assert_no_difference('ObservationUnit.count') do
          assert_no_difference('Sample.count') do
            assert_no_difference('Assay.count') do
              assert_no_difference('ActivityLog.count') do
                FairDataStationUpdateJob.perform_now(upload)
              end
            end
          end
        end
      end
    end
    assert upload.update_task.failed?
    assert_equal 'Seek::FairDataStation::MissingSampleTypeException: Unable to find a matching Sample Type with suitable access rights',
                 upload.update_task.error_message
    assert_match(/block in _perform_job/, upload.update_task.exception)
  end

  def setup_test_case_investigation
    FactoryBot.create(:fairdata_test_case_investigation_extended_metadata)
    FactoryBot.create(:fairdata_test_case_study_extended_metadata)
    FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)

    contributor = FactoryBot.create(:person)
    project = contributor.projects.first
    policy = FactoryBot.create(:public_policy)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, [project], policy)
    assert_difference('Investigation.count', 1) do
      investigation.save!
    end
    assert_equal 'seek-test-investigation', investigation.external_identifier
    investigation
  end
end

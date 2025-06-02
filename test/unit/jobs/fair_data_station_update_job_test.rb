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
    project = investigation.projects.first

    upload = FactoryBot.create(:update_fair_data_station_upload, contributor: person, project: project, investigation: investigation)
    assert_no_difference('Investigation.count') do
      assert_difference('Study.count', 1) do
        assert_difference('ObservationUnit.count', 1) do
          assert_difference('Sample.count', 1) do
            assert_difference('Assay.count', 1) do
              assert_difference('ActivityLog.count',18) do
                FairDataStationUpdateJob.perform_now(upload)
              end
            end
          end
        end
      end
    end
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
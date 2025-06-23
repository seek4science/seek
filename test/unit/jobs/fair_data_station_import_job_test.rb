require 'test_helper'

class FairDataStationImportJobTest < ActiveSupport::TestCase
  def setup
    FactoryBot.create(:fairdata_test_case_investigation_extended_metadata)
    FactoryBot.create(:fairdata_test_case_study_extended_metadata)
    FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)
  end

  test 'perform' do
    upload_record = FactoryBot.create :fair_data_station_upload
    assert_difference('Investigation.count', 1) do
      assert_difference('Study.count', 2) do
        assert_difference('Assay.count', 6) do
          assert_difference('ObservationUnit.count', 3) do
            assert_difference('Sample.count', 5) do
              assert_difference('DataFile.count', 5) do
                assert_difference('ExtendedMetadata.count', 12) do
                  FairDataStationImportJob.perform_now(upload_record)
                end
              end
            end
          end
        end
      end
    end
    upload_record.reload
    assert upload_record.import_task.success?
    inv = upload_record.investigation
    refute_nil inv
    assert_equal 2, inv.studies.count
    assert_equal inv.external_identifier, upload_record.investigation_external_identifier
  end

  test 'error recorded' do
    upload_record = FactoryBot.create :invalid_fair_data_station_upload
    assert_no_difference('Investigation.count') do
      FairDataStationImportJob.perform_now(upload_record)
    end
    upload_record.reload
    assert upload_record.import_task.failed?
    assert_equal 'RuntimeError: Unable to find an Investigation in the FAIR Data Station file',
                 upload_record.import_task.error_message
    assert_match(/block in _perform_job/, upload_record.import_task.exception)
  end

  test 'no sample type recorded' do
    upload_record = FactoryBot.create :fair_data_station_upload
    disable_authorization_checks{ SampleType.destroy_all }
    assert_no_difference('Investigation.count') do
      FairDataStationImportJob.perform_now(upload_record)
    end
    upload_record.reload
    assert upload_record.import_task.failed?
    assert_equal 'Seek::FairDataStation::MissingSampleTypeException: Unable to find a matching Sample Type with suitable access rights',
                 upload_record.import_task.error_message
    assert_match(/block in _perform_job/, upload_record.import_task.exception)
  end

  test 'queue' do
    upload_record = FactoryBot.create :fair_data_station_upload
    assert_enqueued_jobs(1, only: FairDataStationImportJob) do
      FairDataStationImportJob.new(upload_record).queue_job
    end
    upload_record.reload
    assert upload_record.import_task.pending?
  end
end

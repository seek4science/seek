require 'test_helper'

class SampleDataPersistJobTest < ActiveSupport::TestCase
  def setup
    create_sample_attribute_type
    @person = FactoryBot.create(:project_administrator)
    User.current_user = @person.user

    @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob),
                                     policy: FactoryBot.create(:private_policy), contributor: @person
    refute @data_file.sample_template?
    assert_empty @data_file.possible_sample_types

    @sample_type = SampleType.new title: 'from template', uploaded_template: true,
                                  project_ids: [@person.projects.first.id], contributor: @person
    @sample_type.content_blob = FactoryBot.create(:sample_type_template_content_blob)
    @sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    @sample_type.sample_attributes.first.sample_attribute_type = FactoryBot.create(:full_name_sample_attribute_type)
    @sample_type.sample_attributes[1].sample_attribute_type = FactoryBot.create(:datetime_sample_attribute_type)
    @sample_type.save!
  end

  test 'queue job' do
    assert_enqueued_jobs(1, only: SampleDataPersistJob) do
      SampleDataPersistJob.new(@data_file, @sample_type).queue_job
    end
    @data_file.reload
    assert_equal Task::STATUS_QUEUED, @data_file.sample_persistence_task.status
  end

  test 'persists samples' do
    assert_difference('Sample.count', 3) do
      assert_difference('ReindexingQueue.count', 3) do
        assert_difference('AuthLookupUpdateQueue.count', 3) do
          with_config_value(:auth_lookup_enabled, true) do # needed to test added to queue
            SampleDataPersistJob.perform_now(@data_file, @sample_type)
          end
        end
      end
    end

    @data_file.reload

    assert_equal Task::STATUS_DONE, @data_file.sample_persistence_task.status

    assert_equal 3, @data_file.extracted_samples.count
    assert_equal @sample_type, @data_file.extracted_samples.first.sample_type
    assert_equal @person, @data_file.extracted_samples.first.contributor
  end

  test 'persists samples and associate with assay' do
    assay_asset1 = FactoryBot.create(:assay_asset, asset: @data_file, direction: AssayAsset::Direction::INCOMING,
                                         assay: FactoryBot.create(:assay, contributor: @person))
    assay_asset2 = FactoryBot.create(:assay_asset, asset: @data_file, direction: AssayAsset::Direction::OUTGOING,
                                         assay: FactoryBot.create(:assay, contributor: @person))

    assert_difference('AssayAsset.count', 3) do
      assert_difference('Sample.count', 3) do
        SampleDataPersistJob.perform_now(@data_file, @sample_type, assay_ids: [assay_asset1.assay_id])
      end
    end

    @data_file.reload
    @data_file.extracted_samples.each do |sample|
      assert_equal [assay_asset1.assay], sample.assays
      assert_equal assay_asset1.direction, sample.assay_assets.first.direction
    end
  end

  test 'records exception' do
    class FailingSampleDataPersistJob < SampleDataPersistJob
      def perform(data_file, sample_type, assay_ids: nil)
        raise 'critical error'
      end
    end

    FailingSampleDataPersistJob.perform_now(@data_file, @sample_type)

    task = @data_file.sample_persistence_task
    assert task.failed?
    refute_nil task.exception

    # contains message and backtrace
    assert_match /critical error/, task.exception
    assert_match /block in perform_now/, task.exception
    assert_match /activejob/, task.exception

  end
end

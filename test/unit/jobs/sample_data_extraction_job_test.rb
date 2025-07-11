require 'test_helper'

class SampleDataExtractionJobTest < ActiveSupport::TestCase

  def setup
    create_sample_attribute_type
    @person = FactoryBot.create(:project_administrator)
    User.current_user = @person.user
    @project_id = @person.projects.first.id

    @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob),
                         policy: FactoryBot.create(:private_policy), contributor: @person
    refute @data_file.matching_sample_type?
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

  test 'extracts samples' do
    @data_file.policy = FactoryBot.create(:public_policy)
    disable_authorization_checks{@data_file.save!}
    job = SampleDataExtractionJob.new
    assert_no_difference('Sample.count') do
      job.perform(@data_file, @sample_type)
    end
    samples = job.extractor.fetch
    assert_equal 4, samples.count
    samples.each do |sample|
      assert_equal @sample_type, sample.sample_type
      assert_equal [@project_id], sample.project_ids
      assert_equal @person, sample.contributor
    end
  end

  test 'records exception' do
    class FailingSampleDataExtractionJob < SampleDataExtractionJob
      def perform(data_file, sample_type, assay_ids: nil)
        raise 'critical error'
      end
    end

    FailingSampleDataExtractionJob.perform_now(@data_file, @sample_type)

    task = @data_file.sample_extraction_task
    assert task.failed?
    assert_equal 'RuntimeError: critical error', task.error_message
    refute_nil task.exception

    # contains message and backtrace
    assert_match /critical error/, task.exception
    assert_match /block in perform_now/, task.exception
    assert_match /activejob/, task.exception

  end

end

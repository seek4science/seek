require 'test_helper'

class SampleTemplateGeneratorJobTest < ActiveSupport::TestCase
  def setup
    SampleType.skip_callback(:save, :after, :queue_template_generation)
    @sample_type = Factory(:simple_sample_type)
    SampleType.set_callback(:save, :after, :queue_template_generation)
  end

  test 'exists' do
    SampleTemplateGeneratorJob.new(@sample_type).queue_job
    assert SampleTemplateGeneratorJob.new(@sample_type).exists?
  end

  test 'disallow duplicates' do
    assert_difference('Delayed::Job.count', 1) do
      SampleTemplateGeneratorJob.new(@sample_type).queue_job
    end

    assert_no_difference('Delayed::Job.count') do
      SampleTemplateGeneratorJob.new(@sample_type).queue_job
    end
  end

  test 'perform' do
    assert_nil @sample_type.content_blob

    assert_difference('ContentBlob.count', 1) do
      job = SampleTemplateGeneratorJob.new(@sample_type)
      job.perform
    end

    @sample_type.reload

    refute_nil @sample_type.content_blob
    assert File.exist?(@sample_type.content_blob.filepath)
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', @sample_type.content_blob.content_type
    assert_equal "#{@sample_type.title} template.xlsx", @sample_type.content_blob.original_filename
  end
end

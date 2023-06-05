require 'test_helper'

class SampleTemplateGeneratorJobTest < ActiveSupport::TestCase
  def setup
    @sample_type = FactoryBot.create(:simple_sample_type)
  end

  test 'perform' do
    assert_nil @sample_type.content_blob

    assert_difference('ContentBlob.count', 1) do
      SampleTemplateGeneratorJob.perform_now(@sample_type)
    end

    @sample_type.reload

    refute_nil @sample_type.content_blob
    assert File.exist?(@sample_type.content_blob.filepath)
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', @sample_type.content_blob.content_type
    assert_equal "#{@sample_type.title} template.xlsx", @sample_type.content_blob.original_filename
  end
end

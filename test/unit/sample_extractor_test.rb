require 'test_helper'

class SampleExtractorTest < ActiveSupport::TestCase
  
  setup do
    @person = Factory(:person)
    Factory(:string_sample_attribute_type, title:'String')
    @data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: @person.user
    @sample_type = SampleType.new title:'from template'
    @sample_type.content_blob = Factory(:sample_type_template_content_blob)
    @sample_type.build_attributes_from_template
    @sample_type.save!
    @extractor = Seek::Samples::Extractor.new(@data_file, @sample_type)
  end

  test "extracted samples are cached" do
    assert @extractor.fetch.nil?
    @extractor.extract
    assert_not_nil @extractor.fetch
  end

  test "extracted samples are not re-extracted when persisted" do
    @extractor.extract

    disable_authorization_checks { @data_file.content_blob.destroy }
    @data_file.reload
    assert_nil @data_file.content_blob
    assert_difference('Sample.count', 4) do
      @extractor.persist
    end
  end

  test "extracted samples can be cleared" do
    @extractor.extract
    assert_not_nil @extractor.fetch
    @extractor.clear
    assert_nil @extractor.fetch
  end

end

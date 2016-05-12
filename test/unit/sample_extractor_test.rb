require 'test_helper'

class SampleExtractorTest < ActiveSupport::TestCase

  test "extracted samples are cached" do
    person = Factory(:person)
    Factory(:string_sample_attribute_type, title:'String')
    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person.user
    sample_type = SampleType.new title:'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    sample_type.save!
    extractor = Seek::Samples::Extractor.new(data_file, sample_type)

    assert extractor.fetch.nil?
    extractor.extract
    assert_not_nil extractor.fetch
  end

end

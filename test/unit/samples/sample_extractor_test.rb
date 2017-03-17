require 'test_helper'

class SampleExtractorTest < ActiveSupport::TestCase
  setup do
    Factory(:admin) # to avoid first person automatically becoming admin
    @person = Factory(:project_administrator)
    User.current_user = @person.user
    Factory(:string_sample_attribute_type, title: 'String')
    @data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                                     policy: Factory(:private_policy), contributor: @person.user
    @sample_type = SampleType.new title: 'from template', project_ids: [@person.projects.first.id]
    @sample_type.content_blob = Factory(:sample_type_template_content_blob)
    @sample_type.build_attributes_from_template
    @sample_type.save!
    @extractor = Seek::Samples::Extractor.new(@data_file, @sample_type)
    User.current_user = nil
  end

  test 'extracted samples are cached' do
    assert @extractor.fetch.nil?
    @extractor.extract
    assert_not_nil @extractor.fetch
  end

  test 'extracted samples are not re-extracted when persisted' do
    @extractor.extract

    # Delete data file so re-extracting would raise an error
    disable_authorization_checks { @data_file.content_blob.destroy }
    @data_file.reload
    assert_nil @data_file.content_blob
    assert_difference('Sample.count', 4) do
      @extractor.persist
    end
  end

  test 'extracted samples can be cleared' do
    @extractor.extract
    assert_not_nil @extractor.fetch
    @extractor.clear
    assert_nil @extractor.fetch
  end

  test 'blank rows are ignored from sample spreadsheets' do
    @data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_blank_rows_content_blob),
                                     policy: Factory(:private_policy), contributor: @person.user
    @extractor = Seek::Samples::Extractor.new(@data_file, @sample_type)

    accepted, rejected = @extractor.extract.partition(&:valid?)

    assert_equal 4, accepted.length
    assert_equal 0, rejected.length
    assert_equal ['Bob Monkhouse', 'Jesus Jones', 'Fred Flintstone', 'Bob'].sort,
                 accepted.map { |s| s.data[:full_name] }.sort
  end
end

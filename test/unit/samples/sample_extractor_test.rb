require 'test_helper'

class SampleExtractorTest < ActiveSupport::TestCase
  setup do
    FactoryBot.create(:admin) # to avoid first person automatically becoming admin
    @person = FactoryBot.create(:project_administrator)
    User.current_user = @person.user
    create_sample_attribute_type
    @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob),
                                     policy: FactoryBot.create(:private_policy), contributor: @person
    @sample_type = SampleType.new title: 'from template', project_ids: [@person.projects.first.id], contributor: @person
    @sample_type.content_blob = FactoryBot.create(:sample_type_template_content_blob)
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

    User.with_current_user @person.user do
      # Delete data file so re-extracting would raise an error
      @data_file.content_blob.destroy
      @data_file.reload
      assert_nil @data_file.content_blob
      assert_difference('Sample.count', 4) do
        @extractor.persist
      end
    end
  end

  test 'extracted samples can be cleared' do
    @extractor.extract
    assert_not_nil @extractor.fetch
    @extractor.clear
    assert_nil @extractor.fetch
  end

  test 'blank rows are ignored from sample spreadsheets' do
    @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_blank_rows_content_blob),
                                     policy: FactoryBot.create(:private_policy), contributor: @person
    @extractor = Seek::Samples::Extractor.new(@data_file, @sample_type)

    accepted, rejected = @extractor.extract.partition(&:valid?)

    assert_equal 4, accepted.length
    assert_equal 0, rejected.length
    assert_equal ['Bob Monkhouse', 'Jesus Jones', 'Fred Flintstone', 'Bob'].sort,
                 accepted.map { |s| s.data['full name'] }.sort
  end
end

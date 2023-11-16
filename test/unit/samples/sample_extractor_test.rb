require 'test_helper'

class SampleExtractorTest < ActiveSupport::TestCase
  setup do
    FactoryBot.create(:admin) # to avoid first person automatically becoming admin
    @person = FactoryBot.create(:project_administrator)
    User.with_current_user(@person.user) do
      create_sample_attribute_type
      @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob),
                                     policy: FactoryBot.create(:private_policy), contributor: @person
      @sample_type = SampleType.new title: 'from template', project_ids: [@person.projects.first.id], contributor: @person
      @sample_type.content_blob = FactoryBot.create(:sample_type_template_content_blob)
      @sample_type.build_attributes_from_template
      @sample_type.save!
      @extractor = Seek::Samples::Extractor.new(@data_file, @sample_type)
    end
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

  test 'extractor handles links to private samples' do
    person = FactoryBot.create(:person)
    template_data_file = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:linked_samples_with_patient_content_blob))
    sample_type = FactoryBot.create(:linked_sample_type, title: 'Parent Sample Type', contributor: person)
    sample_type.sample_attributes.detect { |attr| attr.title == 'title' }.update_column(:template_column_index, 1)
    sample_type.sample_attributes.detect { |attr| attr.title == 'patient' }.update_column(:template_column_index, 2)
    FactoryBot.create(:linked_samples_with_patient_content_blob, asset: sample_type)
    sample_type.reload

    child_sample_type = sample_type.sample_attributes.last.linked_sample_type

    child_sample1 = Sample.create(sample_type: child_sample_type, contributor: person, projects: person.projects, data: { 'full name': 'Patient One', 'age': 20 }, policy: FactoryBot.create(:private_policy))
    child_sample2 = Sample.create(sample_type: child_sample_type, contributor: person, projects: person.projects, data: { 'full name': 'Patient Two', 'age': 20 }, policy: FactoryBot.create(:private_policy))

    assert sample_type.valid?
    refute_nil sample_type.content_blob

    assert child_sample1.valid?
    assert_equal 'Patient One', child_sample1.title
    refute child_sample1.can_view?
    assert child_sample2.valid?
    assert_equal 'Patient Two', child_sample2.title
    refute child_sample2.can_view?

    assert_includes template_data_file.possible_sample_types(person.user), sample_type
    assert_equal 2, template_data_file.extract_samples(sample_type, false, false).count

    assert_difference('Sample.count', 2) do
      extracted_samples = Seek::Samples::Extractor.new(template_data_file, sample_type).persist(person.user)
      assert_equal 2, extracted_samples.count
      assert_equal ['sample one', 'sample two'], extracted_samples.collect(&:title).sort
      sample1 = extracted_samples.detect{|s| s.title=='sample one'}
      sample2 = extracted_samples.detect{|s| s.title=='sample two'}

      # check the linked resources have been updated via a callback
      assert_equal [child_sample1], sample1.linked_samples
      assert_equal [child_sample2], sample2.linked_samples

      # check the title is set and saved via a callback
      assert_equal 'sample one', Sample.find(sample1.id).title
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

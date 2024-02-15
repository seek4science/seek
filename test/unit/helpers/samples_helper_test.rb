require 'test_helper'

class SamplesHelperTest < ActionView::TestCase
  test 'seek sample attribute display' do
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:public_policy))
    assert sample.can_view?
    value = { id: sample.id, title: sample.title, type: 'Sample' }.with_indifferent_access
    display = seek_sample_attribute_display(value)
    tag = Nokogiri::HTML::DocumentFragment.parse(display).children.first
    assert_equal 'a', tag.name
    assert_equal "/samples/#{sample.id}", tag['href']
    assert_equal sample.title, tag.children.first.content

    # private sample
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy))
    refute sample.can_view?
    value = { id: sample.id, title: sample.title, type: 'Sample' }.with_indifferent_access
    display = seek_sample_attribute_display(value)
    tag = Nokogiri::HTML::DocumentFragment.parse(display).children.first
    assert_equal 'span', tag.name
    assert_equal 'none_text', tag['class']
    assert_equal 'Hidden', tag.children.first.content

    # doesn't exist
    value = { id: (Sample.maximum(:id)+1), title: 'Blah', type: 'Sample' }.with_indifferent_access
    display = seek_sample_attribute_display(value)
    tag = Nokogiri::HTML::DocumentFragment.parse(display).children.first
    assert_equal 'span', tag.name
    assert_equal 'none_text', tag['class']
    assert_equal 'Blah', tag.children.first.content
  end

  test 'sample_attribute_display_title' do
    # simple
    attribute = FactoryBot.create(:sample_sample_attribute, title:'The title',sample_type: FactoryBot.create(:simple_sample_type))
    assert_equal 'The title',sample_attribute_display_title(attribute)

    #unit
    attribute = FactoryBot.create(:sample_sample_attribute, title:'The title',unit:FactoryBot.create(:unit),sample_type: FactoryBot.create(:simple_sample_type))
    assert_equal 'The title ( g )',sample_attribute_display_title(attribute)

    #pid
    attribute = FactoryBot.create(:sample_sample_attribute, title:'The title',pid:'http://pid.org/attr#title',sample_type: FactoryBot.create(:simple_sample_type))
    assert_equal "The title<small data-tooltip=\"http://pid.org/attr#title\"> [ title ]</small>",sample_attribute_display_title(attribute)
  end

  test 'attempt to show sample extract button' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      # no sample types
      data_file = FactoryBot.create(:xlsx_spreadsheet_datafile, contributor: person)
      refute attempt_to_show_extract_samples_button?(data_file, data_file.latest_version)

      FactoryBot.create(:min_sample_type)
      # good
      assert attempt_to_show_extract_samples_button?(data_file, data_file.latest_version)

      # no manage permissions
      data_file = FactoryBot.create(:xlsx_spreadsheet_datafile)
      refute attempt_to_show_extract_samples_button?(data_file, data_file.latest_version)

      # not a spreadsheet
      data_file = FactoryBot.create(:non_spreadsheet_datafile, contributor: person)
      refute attempt_to_show_extract_samples_button?(data_file, data_file.latest_version)

      # not the latest version
      data_file = FactoryBot.create(:xlsx_spreadsheet_datafile, contributor: person)
      data_file.save_as_new_version
      FactoryBot.create(:xlsx_content_blob, asset: data_file, asset_version: data_file.version)
      data_file.reload
      refute attempt_to_show_extract_samples_button?(data_file, data_file.versions.first)

      # has extracted samples
      data_file = FactoryBot.create(:xlsx_spreadsheet_datafile, contributor: person)
      data_file.extracted_samples << FactoryBot.create(:sample)
      refute attempt_to_show_extract_samples_button?(data_file, data_file.latest_version)

      # in progress
      data_file = FactoryBot.create(:xlsx_spreadsheet_datafile, contributor: person)
      data_file.sample_extraction_task.update_attribute(:status, Task::STATUS_ACTIVE)
      assert data_file.sample_extraction_task.in_progress?
      refute attempt_to_show_extract_samples_button?(data_file, data_file.latest_version)
    end
  end
end

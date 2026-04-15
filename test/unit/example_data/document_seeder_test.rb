require 'test_helper'
class DocumentSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
    @admin_person = FactoryBot.create(:admin, first_name: 'Admin', last_name: 'Person')
    @guest_person = FactoryBot.create(:person, first_name: 'Guest', last_name: 'User')
    @project = @guest_person.projects.first
    @seed_data_dir = File.join(Rails.root, 'db', 'seeds', 'example_data')
  end

  def teardown
    User.current_user = nil
  end

  test 'seed document' do
    seeder = Seek::ExampleData::DocumentSeeder.new(
      @project, @guest_person, @admin_person, @seed_data_dir
    )
    result = nil
    assert_difference('Document.count', 1) do
      result = seeder.seed
      assert_includes result.keys, :document
      assert_not_nil result[:document]
    end

    doc = result[:document].reload
    assert_equal 'Experimental setup for the reconstituted gluconeogenic enzyme system', doc.title
    assert_equal 'This document describes the experimental setup and procedures used for reconstituting the gluconeogenic enzyme system from Sulfolobus solfataricus.', doc.description
    assert_equal @project, doc.projects.first
    assert_equal @guest_person, doc.contributor
    assert_equal 'example_document.txt', doc.content_blob.original_filename
    assert doc.content_blob.file_exists?
    assert_equal 'CC-BY-SA-4.0', doc.license
    assert_equal [@admin_person], doc.creators
    assert_nil doc.other_creators
    assert_equal %w[gluconeogenesis protocol thermophile], doc.tags
  end

end

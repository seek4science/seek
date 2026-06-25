require 'test_helper'
require 'storage_stub_helper'

class DocumentsSeederTest < ActiveSupport::TestCase
  include StorageStubHelper

  def setup
    User.current_user = nil
    @admin_person = FactoryBot.create(:admin, first_name: 'Admin', last_name: 'Person')
    @guest_person = FactoryBot.create(:person, first_name: 'Guest', last_name: 'User')
    @project = @guest_person.projects.first
    @seed_data_dir = File.join(Rails.root, 'db', 'seeds', 'example_data')
    disable_std_output
  end

  def teardown
    User.current_user = nil
    enable_std_output
  end

  test 'seed document' do
    seeder = Seek::ExampleData::DocumentsSeeder.new(
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
    assert_equal 'This document describes the experimental setup and procedures used for reconstituting the gluconeogenic enzyme system from Sulfolobus solfataricus.',
                 doc.description
    assert_equal @project, doc.projects.first
    assert_equal @guest_person, doc.contributor
    assert_equal 'example_document.txt', doc.content_blob.original_filename
    assert doc.content_blob.file_exists?
    assert_equal 'CC-BY-SA-4.0', doc.license
    assert_equal [@admin_person], doc.creators
    assert_nil doc.other_creators
    assert_equal %w[gluconeogenesis protocol thermophile], doc.tags
  end

  # Seeding must store the file through the storage adapter, not by copying to a local filepath
  # (which does not exist on S3). Stub the S3 adapter and assert the seeded blob lands in object
  # storage with content (issue 2.K).
  test 'seeded document is stored via the adapter on S3' do
    seed_file = File.join(@seed_data_dir, 'example_document.txt')
    bytes = File.binread(seed_file)

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: bytes.bytesize)
      client.stub_responses(:get_object, body: bytes)

      seeder = Seek::ExampleData::DocumentsSeeder.new(
        @project, @guest_person, @admin_person, @seed_data_dir
      )
      result = seeder.seed
      blob = result[:document].reload.content_blob

      assert blob.file_exists?, 'seeded blob should exist in object storage on S3'
      assert blob.file_size.to_i > 0, 'seeded blob should have non-zero size on S3'
    end
  end
end

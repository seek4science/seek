require 'test_helper'
require 'storage_stub_helper'

class SamplesReaderTest < ActiveSupport::TestCase
  include StorageStubHelper

  def setup
    # need a string type registered
    create_sample_attribute_type

    @content_blob = FactoryBot.create(:sample_type_template_content_blob)
    @content_blob2 = FactoryBot.create(:sample_type_template_content_blob2)
    @binary_blob = FactoryBot.create(:binary_content_blob)
  end

  # spreadsheet->XML uses the POI JAR, which needs a real local file. On S3 the template
  # blob has no local path, so it must stream a temporary copy. Runs the real JAR against a copy
  # streamed from a stubbed S3 backend and checks the XML matches the local-backend run.
  test 'template_xml reads the spreadsheet from S3 via a temporary copy' do
    xls_bytes = File.binread(@content_blob.filepath)
    expected = Seek::Templates::SamplesReader.new(@content_blob).send(:template_xml)
    refute_empty expected.to_s, 'expected the local POI run to produce template XML'
    Rails.cache.clear # force the S3 run to re-execute rather than hit the cached result

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: xls_bytes.bytesize)
      client.stub_responses(:get_object, body: xls_bytes)

      result = Seek::Templates::SamplesReader.new(ContentBlob.find(@content_blob.id)).send(:template_xml)
      assert_equal expected, result, 'template XML from S3 should match the local-backend output'
    end
  end

  test 'compatible?' do
    assert Seek::Templates::SamplesReader.new(@content_blob).compatible?
    assert Seek::Templates::SamplesReader.new(@content_blob2).compatible?

    refute Seek::Templates::SamplesReader.new(@binary_blob).compatible?
    refute Seek::Templates::SamplesReader.new(FactoryBot.create(:rightfield_content_blob)).compatible?
    refute Seek::Templates::SamplesReader.new(nil).compatible?
  end

  test 'sheet index' do
    handler = Seek::Templates::SamplesReader.new(@content_blob)
    assert_equal 2, handler.send(:sheet_index)

    handler = Seek::Templates::SamplesReader.new(@content_blob2)
    assert_equal 3, handler.send(:sheet_index)
  end

  test 'column details' do
    handler = Seek::Templates::SamplesReader.new(@content_blob)
    column_details = handler.column_details
    labels = column_details.collect(&:label)
    assert_equal ['full name', 'date of birth', 'hair colour', 'eye colour'], labels
    columns = column_details.collect(&:column)
    assert_equal [1, 2, 3, 4], columns

    handler = Seek::Templates::SamplesReader.new(@content_blob2)
    column_details = handler.column_details
    labels = column_details.collect(&:label)
    assert_equal ['full name', 'date of birth', 'hair colour', 'eye colour'], labels
    columns = column_details.collect(&:column)
    assert_equal [3, 7, 10, 11], columns

    handler = Seek::Templates::SamplesReader.new(@binary_blob)
    assert_nil handler.column_details
  end

  test 'each record' do
    handler = Seek::Templates::SamplesReader.new(FactoryBot.create(:sample_type_populated_template_content_blob))
    rows = []
    data = []
    handler.each_record do |row, d|
      rows << row
      data << d
    end
    assert_equal 4, rows.count
    assert_equal [2, 3, 4, 5], rows
    assert_equal 4, data.count
    assert_equal [1, 2, 3, 4], data.first.collect(&:column)
    values = data.first.collect(&:value)
    values[1] = Date.parse(values[1])
    assert_equal ['Bob Monkhouse', Date.parse('12 March 1970'), 'Blue', 'Yellow'], values

    assert_equal [1, 2, 3, 4], data.last.collect(&:column)
    values = data.last.collect(&:value)
    values[1] = Date.parse(values[1])
    assert_equal ['Bob', Date.parse('2 January 1900'), 'Pink', 'Green'], values
  end

  test 'each record restricted columns' do
    handler = Seek::Templates::SamplesReader.new(FactoryBot.create(:sample_type_populated_template_content_blob))
    rows = []
    data = []
    handler.each_record([1, 4]) do |row, d|
      rows << row
      data << d
    end
    assert_equal 4, rows.count
    assert_equal [2, 3, 4, 5], rows
    assert_equal 4, data.count
    assert_equal [1, 4], data.first.collect(&:column)
    assert_equal ['Bob Monkhouse', 'Yellow'], data.first.collect(&:value)

    assert_equal [1, 4], data.last.collect(&:column)
    assert_equal %w(Bob Green), data.last.collect(&:value)
  end
end

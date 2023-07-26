require 'test_helper'

class SamplesReaderTest < ActiveSupport::TestCase
  def setup
    # need a string type registered
    create_sample_attribute_type

    @content_blob = FactoryBot.create(:sample_type_template_content_blob)
    @content_blob2 = FactoryBot.create(:sample_type_template_content_blob2)
    @binary_blob = FactoryBot.create(:binary_content_blob)
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

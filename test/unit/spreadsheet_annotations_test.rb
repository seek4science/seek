require 'test_helper'

class SpreadsheetAnnotationsTest < ActiveSupport::TestCase
  fixtures :all

  test 'saving an annotation to a user' do
    ann = create_annotation(users(:datafile_owner), cell_ranges(:cell_range_1), 'annotation', 'this is an annotation value')
    assert ann.save
    ann.reload
    assert_equal ann.source, users(:datafile_owner)
  end

  test 'source is saved correctly' do
    ann = create_annotation(users(:datafile_owner), cell_ranges(:cell_range_2), 'annotation', 'this is an annotation value')
    assert ann.save
    ann.reload
    assert_equal ann.source, users(:datafile_owner)
  end

  test 'check spreadsheet_annotations method returns all of the users annotations' do
    # target user
    user = users(:datafile_owner)

    # get all data files owned by the datafile_owner
    data_files = DataFile.all
    df = data_files.select { |x| x.contributor == user.id }

    # check that the owners datafile.spreadsheet_annotations returns all annotation values
    df.each { |spreadsheet| Annotations.each { |annotations| assert ((annotations.value.text == spreadsheet.spreadsheet_annotations.value.text) && !annotations.value.text.nil? && !spreadsheet.spreadsheet_annotations.value.text.nil?) } }
  end

  def create_annotation(source = nil, annotatable = nil, attribute_name = nil, value = nil)
    Annotation.new(source: source,
                   annotatable: annotatable,
                   attribute_name: attribute_name,
                   value: value)
  end
end

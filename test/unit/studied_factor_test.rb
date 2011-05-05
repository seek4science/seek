require 'test_helper'

class StudiedFactorTest < ActiveSupport::TestCase
  fixtures :all
  test 'should create FS with the concentration of the compound' do
    measured_item = measured_items(:concentration)
    unit = units(:gram)
    compound = compounds(:compound_with_title)
    data_file = data_files(:editable_data_file)
    fs = StudiedFactor.new(:data_file => data_file, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :compound => compound)
    assert fs.save, "should create the new factor studied with the concentration of the compound "
  end

  test 'should not create FS with the concentration of no compound' do
    measured_item = measured_items(:concentration)
    unit = units(:gram)
    data_file = data_files(:editable_data_file)
    fs = StudiedFactor.new(:data_file => data_file, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :compound => nil)
    assert !fs.save, "shouldn't create factor studied with concentration of no compound"
  end

  test 'should create FS with the none concentration item and no compound' do
    measured_item = measured_items(:time)
    unit = units(:second)
    data_file = data_files(:editable_data_file)
    fs = StudiedFactor.new(:data_file => data_file, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :compound => nil)
    assert fs.save, "should create factor studied  of the none concentration item and no compound"
  end
end

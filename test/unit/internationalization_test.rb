require 'test_helper'

class InternationalizationTest < ActiveSupport::TestCase
  test 'assay' do
    assert_equal 'Assay', (I18n.t 'assays.assay')
    assert_equal 'Experimental assay', (I18n.t 'assays.experimental_assay')
    assert_equal 'Modelling analysis', (I18n.t 'assays.modelling_analysis')
  end

  test 'sop' do
    assert_equal 'SOP', (I18n.t 'sop')
  end

  test 'presentation' do
    assert_equal 'Presentation', (I18n.t 'presentation')
  end

  test 'data file' do
    assert_equal 'Data file', (I18n.t 'data_file')
  end

  test 'investigation' do
    assert_equal 'Investigation', (I18n.t 'investigation')
  end

  test 'study' do
    assert_equal 'Study', (I18n.t 'study')
  end

  test 'model' do
    assert_equal 'Model', (I18n.t 'model')
  end

  test 'event' do
    assert_equal 'Event', (I18n.t 'event')
  end

  test 'project' do
    assert_equal 'Project', (I18n.t 'project')
  end
end

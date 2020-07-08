require 'test_helper'

class GalaxyExtractionTest < ActiveSupport::TestCase
  test 'extracts metadata from Galaxy workflow file' do
    wf = open_fixture_file('workflows/1-PreProcessing.ga')
    extractor = Seek::WorkflowExtractors::Galaxy.new(wf)
    metadata = extractor.metadata
    internals = metadata[:internals]

    assert_equal '1 - read pre-processing', metadata[:title]
    assert_equal ['covid-19'], metadata[:tags]
    assert_equal 1, internals[:inputs].length
    assert_equal 17, internals[:steps].length
    assert_equal 31, internals[:outputs].length
    input = internals[:inputs].detect { |i| i[:id] == 'bed_file' }
    assert_equal 'bed_file', input[:name]
    assert_equal 'runtime parameter for tool Filter SAM or BAM, output SAM or BAM', input[:description]

  end

  test 'extracts metadata from Galaxy workflow RO crate' do
    wf = open_fixture_file('workflows/1-PreProcessing.crate.zip')
    extractor = Seek::WorkflowExtractors::ROCrate.new(wf)
    metadata = extractor.metadata
    internals = metadata[:internals]

    assert_equal '1 - read pre-processing', metadata[:title]
    assert_equal '<h1>Preprocessing of raw SARS-CoV-2 reads</h1>', metadata[:description].split("\n").first, 'Should have parsed description from README.md'
    assert_equal ['covid-19'], metadata[:tags]
    assert_equal 1, internals[:inputs].length
    assert_equal 17, internals[:steps].length
    assert_equal 31, internals[:outputs].length
    input = internals[:inputs].detect { |i| i[:id] == 'bed_file' }
    assert_equal 'bed_file', input[:name]
    assert_equal 'runtime parameter for tool Filter SAM or BAM, output SAM or BAM', input[:description]
  end
end

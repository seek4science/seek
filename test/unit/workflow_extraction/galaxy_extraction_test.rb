require 'test_helper'

class GalaxyExtractionTest < ActiveSupport::TestCase
  setup do
    @galaxy = WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class)
  end

  test 'extracts metadata from Galaxy workflow file' do
    wf = open_fixture_file('workflows/1-PreProcessing.ga')
    extractor = Seek::WorkflowExtractors::Galaxy.new(wf)
    metadata = extractor.metadata
    internals = metadata[:internals]

    assert_equal '1 - read pre-processing', metadata[:title]
    assert_equal ['covid-19'], metadata[:tags]
    assert_equal 2, internals[:inputs].length
    assert_equal 15, internals[:steps].length
    assert_equal 31, internals[:outputs].length
    input = internals[:inputs].detect { |i| i[:id] == 'List of Illumina accessions' }
    assert_equal 'List of Illumina accessions', input[:name]
  end

  test 'extracts metadata from Galaxy workflow RO-Crate' do
    wf = open_fixture_file('workflows/1-PreProcessing.crate.zip')
    extractor = Seek::WorkflowExtractors::ROCrate.new(wf)
    metadata = extractor.metadata
    internals = metadata[:internals]

    assert_equal @galaxy.id, metadata[:workflow_class_id]
    assert_equal '1 - read pre-processing', metadata[:title]
    assert_equal '# Preprocessing of raw SARS-CoV-2 reads', metadata[:description].split("\n").first, 'Should have parsed description from README.md'
    assert_equal ['covid-19'], metadata[:tags]
    assert_equal 'https://github.com/galaxyproject/SARS-CoV-2', metadata[:source_link_url]
    assert_equal 2, internals[:inputs].length
    assert_equal 15, internals[:steps].length
    assert_equal 31, internals[:outputs].length
    input = internals[:inputs].detect { |i| i[:id] == 'List of Illumina accessions' }
    assert_equal 'List of Illumina accessions', input[:name]
  end
end

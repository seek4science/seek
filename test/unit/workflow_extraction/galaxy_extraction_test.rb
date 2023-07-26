require 'test_helper'

class GalaxyExtractionTest < ActiveSupport::TestCase
  setup do
    @galaxy = WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class)
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

  test 'extracts metadata from Galaxy workflow with subworkflow' do
    wf = open_fixture_file('workflows/VGP_Bionano/Galaxy-Workflow-VGP_Bionano.ga')
    extractor = Seek::WorkflowExtractors::Galaxy.new(wf)
    metadata = nil
    assert_nothing_raised do
      metadata = extractor.metadata
    end

    internals = metadata[:internals]
    assert_equal 'VGP Bionano', metadata[:title]
    assert_equal 'CC-BY-4.0', metadata[:license]
    assert_equal 'Performs scaffolding using Bionano Data. Part of VGP assembly pipeline.', metadata[:description].strip
    assert_equal 5, internals[:inputs].length
    assert_equal 6, internals[:steps].length
    assert_equal 9, internals[:outputs].length
    input = internals[:steps].detect { |i| i[:id] == '10' }
    assert_equal 'Plot gfastats output', input[:name]
    assert_equal '177600', input[:description]
  end

  test 'extracts bio.tools IDs from galaxy workflow' do
    # Prime cache
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        with_config_value(:galaxy_tool_sources, ['https://usegalaxy.eu/api', 'https://usegalaxy.org.au/api']) do
          Galaxy::ToolMap.instance.refresh
        end
      end
    end

    wf = open_fixture_file('workflows/1-PreProcessing.ga')
    extractor = Seek::WorkflowExtractors::Galaxy.new(wf)
    metadata = extractor.metadata

    assert_equal [{ bio_tools_id: 'multiqc', name: 'MultiQC' }], metadata[:tools_attributes]
  end
end

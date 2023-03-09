require 'test_helper'

class GalaxyToolMapTest < ActiveSupport::TestCase
  COMMON_TOOL = 'toolshed.g2.bx.psu.edu/repos/iuc/multiqc/multiqc'
  EU_TOOL = 'toolshed.g2.bx.psu.edu/repos/iuc/enasearch_search_data/enasearch_search_data'
  AUS_TOOL = 'toolshed.g2.bx.psu.edu/repos/iuc/bcftools_plugin_fill_tags/bcftools_plugin_fill_tags'
  GALAXY_EU = 'https://usegalaxy.eu/api'
  GALAXY_AUS = 'https://usegalaxy.org.au/api'

  setup do
    @map = Galaxy::ToolMap.instance
    @map.clear
  end

  test 'can refresh map with configured tool source' do
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        with_config_value(:galaxy_tool_sources, [GALAXY_EU]) do
          @map.refresh
        end

        assert_equal 2, @map.map.values.length
        assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))
        assert_nil @map.lookup(AUS_TOOL)
        assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, @map.lookup(EU_TOOL))
        assert Rails.cache.read(Galaxy::ToolMap::CACHE_KEY)[COMMON_TOOL]
      end

      @map.clear

      # Need to reload the cassette here, or it doesn't match again... not sure why!
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        with_config_value(:galaxy_tool_sources, [GALAXY_AUS]) do
          @map.refresh
        end
        assert_equal 2, @map.map.values.length
        assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))
        assert_equal({ bio_tools_id: 'bcftools', name: 'BCFtools' }, @map.lookup(AUS_TOOL))
      end
    end
  end

  test 'can refresh map with multiple tool sources' do
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        assert_nil @map.lookup(COMMON_TOOL)
        assert_nil @map.lookup(AUS_TOOL)
        assert_nil @map.lookup(EU_TOOL)

        with_config_value(:galaxy_tool_sources, [GALAXY_EU, GALAXY_AUS]) do
          @map.refresh
        end

        assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))
        assert_equal({ bio_tools_id: 'bcftools', name: 'BCFtools' }, @map.lookup(AUS_TOOL))
        assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, @map.lookup(EU_TOOL))
      end
    end
  end

  test 'should gracefully handle error responses' do
    VCR.use_cassette('galaxy/fetch_tools_errors') do
      assert_nil @map.lookup(COMMON_TOOL)
      assert_nil @map.lookup(AUS_TOOL)
      assert_nil @map.lookup(EU_TOOL)

      with_config_value(:galaxy_tool_sources, [GALAXY_EU, GALAXY_AUS]) do
        @map.refresh
      end

      assert_nil @map.lookup(COMMON_TOOL)
      assert_nil @map.lookup(AUS_TOOL)
      assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, @map.lookup(EU_TOOL))
    end
  end

  test 'cached values should be preserved in case of error' do
    with_config_value(:galaxy_tool_sources, [GALAXY_EU, GALAXY_AUS]) do
      assert_nil @map.lookup(COMMON_TOOL)

      VCR.use_cassette('galaxy/fetch_tools_trimmed') do
        VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
          @map.refresh
        end
      end

      assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))

      VCR.use_cassette('galaxy/fetch_tools_errors') do
        @map.refresh
      end
    end

    assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))
    assert_equal({ bio_tools_id: 'bcftools', name: 'BCFtools' }, @map.lookup(AUS_TOOL))
    assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, @map.lookup(EU_TOOL))
  end

  test 'can refresh using configured tool sources' do
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        assert_nil @map.lookup(COMMON_TOOL)
        assert_nil @map.lookup(AUS_TOOL)
        assert_nil @map.lookup(EU_TOOL)
        assert_nil Rails.cache.read(Galaxy::ToolMap::CACHE_KEY)

        with_config_value(:galaxy_tool_sources, [GALAXY_EU]) do
          @map.refresh
        end

        assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))
        assert_nil @map.lookup(AUS_TOOL)
        assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, @map.lookup(EU_TOOL))
        assert Rails.cache.read(Galaxy::ToolMap::CACHE_KEY)[COMMON_TOOL]
      end
    end
  end

  test 'can clear map' do
    with_config_value(:galaxy_tool_sources, [GALAXY_EU, GALAXY_AUS]) do
      assert_nil @map.lookup(COMMON_TOOL)

      VCR.use_cassette('galaxy/fetch_tools_trimmed') do
        VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
          @map.refresh
        end
      end

      assert_equal 3, @map.map.values.length
      assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))

      @map.clear
      assert_equal 0, @map.map.values.length
      assert_nil @map.lookup(COMMON_TOOL)
    end
  end
end

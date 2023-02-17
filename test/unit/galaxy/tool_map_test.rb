require 'test_helper'

class GalaxyToolMapTest < ActiveSupport::TestCase
  COMMON_TOOL = 'toolshed.g2.bx.psu.edu/repos/iuc/multiqc/multiqc'
  EU_TOOL = 'toolshed.g2.bx.psu.edu/repos/iuc/enasearch_search_data/enasearch_search_data'
  AU_TOOL = 'toolshed.g2.bx.psu.edu/repos/iuc/bcftools_plugin_fill_tags/bcftools_plugin_fill_tags'
  GALAXY_EU = 'https://usegalaxy.eu/api'
  GALAXY_AUS = 'https://usegalaxy.org.au/api'

  setup do
    @map = Galaxy::ToolMap.new
  end

  test 'can fetch galaxy tools' do
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        t = @map.fetch_galaxy_tools(GALAXY_EU)
        assert_equal 2, t.values.length
        assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, t[COMMON_TOOL])
        assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, t[EU_TOOL])

      end
      # Need to reload the cassette here, or it doesn't match again... not sure why!
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        t = @map.fetch_galaxy_tools(GALAXY_AUS)
        assert_equal 2, t.values.length
        assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, t[COMMON_TOOL])
        assert_equal({ bio_tools_id: 'bcftools', name: 'BCFtools' }, t[AU_TOOL])
      end
    end
  end

  test 'can populate tool map from multiple instances' do
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        assert_nil @map.lookup(COMMON_TOOL)
        assert_nil @map.lookup(AU_TOOL)
        assert_nil @map.lookup(EU_TOOL)

        @map.populate(GALAXY_EU, GALAXY_AUS)

        assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))
        assert_equal({ bio_tools_id: 'bcftools', name: 'BCFtools' }, @map.lookup(AU_TOOL))
        assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, @map.lookup(EU_TOOL))
      end
    end
  end

  test 'should gracefully handle error responses' do
    VCR.use_cassette('galaxy/fetch_tools_errors') do
      assert_nil @map.lookup(COMMON_TOOL)
      assert_nil @map.lookup(AU_TOOL)
      assert_nil @map.lookup(EU_TOOL)

      @map.populate(GALAXY_EU, GALAXY_AUS)

      assert_nil @map.lookup(COMMON_TOOL)
      assert_nil @map.lookup(AU_TOOL)
      assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, @map.lookup(EU_TOOL))
    end
  end

  test 'cached values should be preserved in case of error' do
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        @map.populate(GALAXY_EU, GALAXY_AUS)
      end
    end

    VCR.use_cassette('galaxy/fetch_tools_errors') do
      @map.populate(GALAXY_EU, GALAXY_AUS)
    end

    assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, @map.lookup(COMMON_TOOL))
    assert_equal({ bio_tools_id: 'bcftools', name: 'BCFtools' }, @map.lookup(AU_TOOL))
    assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, @map.lookup(EU_TOOL))
  end

  test 'can refresh using configured tool sources' do
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
        map = Galaxy::ToolMap.instance

        assert_nil map.lookup(COMMON_TOOL)
        assert_nil map.lookup(AU_TOOL)
        assert_nil map.lookup(EU_TOOL)
        assert_nil Rails.cache.read(Galaxy::ToolMap::CACHE_KEY)

        with_config_value(:galaxy_tool_sources, [GALAXY_EU]) do
          Galaxy::ToolMap.refresh
        end

        assert_equal({ bio_tools_id: 'multiqc', name: 'MultiQC' }, map.lookup(COMMON_TOOL))
        assert_nil map.lookup(AU_TOOL)
        assert_equal({ bio_tools_id: 'ena', name: 'European Nucleotide Archive (ENA)' }, Galaxy::ToolMap.lookup(EU_TOOL))
        assert Rails.cache.read(Galaxy::ToolMap::CACHE_KEY)[COMMON_TOOL]
      end
    end
  end
end

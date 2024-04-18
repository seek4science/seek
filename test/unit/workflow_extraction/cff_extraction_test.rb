require 'test_helper'

class CffExtractionTest < ActiveSupport::TestCase
  test 'can extract metadata from complete CFF file' do
    cff = open_fixture_file('CITATION.cff')
    extractor = Seek::WorkflowExtractors::CFF.new(cff)

    assert_nothing_raised do
      metadata = extractor.metadata

      assert_equal 1, metadata[:assets_creators_attributes].length
      creator = metadata[:assets_creators_attributes].values.first
      assert_equal 'Real Person', creator[:family_name]
      assert_equal 'One Truly', creator[:given_name]
      assert_equal 'Excellent University, Niceplace, Arcadia', creator[:affiliation]
      assert_equal 'https://orcid.org/0000-0001-2345-6789', creator[:orcid]
      assert_equal 0, creator[:pos]
      assert_equal 'Entity Project Team Conference entity', metadata[:other_creators]
      assert_equal 'Citation File Format 1.0.0', metadata[:title]
      assert_equal 'CC-BY-SA-4.0', metadata[:license]
      assert_equal ['One', 'Two', 'Three', '4'], metadata[:tags]
      assert_equal '10.5281/zenodo.1003150', metadata[:doi]
      assert_equal 'http://userid:password@example.com:8080/', metadata[:source_link_url]
    end
  end
end

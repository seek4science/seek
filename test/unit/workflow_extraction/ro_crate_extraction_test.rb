require 'test_helper'

class RoCrateExtractionTest < ActiveSupport::TestCase
  test 'extracts metadata from ro-crate' do
    wf = open_fixture_file('workflows/author_test.crate.zip')
    extractor = Seek::WorkflowExtractors::ROCrate.new(wf)
    metadata = extractor.metadata

    assert_equal 'My First Workflow', metadata[:title]
    assert_equal 'It does stuff', metadata[:description]
    assert_equal 'MIT', metadata[:license]
    assert_equal 'https://covid19.workflowhub.eu/workflows/12345/ro_crate?version=1', metadata[:source_link_url]
    assert_equal "Cool University, Dave's Ice Cream Shop", metadata[:other_creators]

    author_meta = metadata[:assets_creators_attributes].values
    assert_equal 3, author_meta.length

    first = author_meta.detect { |a| a[:given_name] == 'Jane' }
    assert first
    assert_equal 'Smith', first[:family_name]
    assert_nil first[:affiliation]
    assert_nil first[:orcid]
    assert_equal 0, first[:pos]

    second = author_meta.detect { |a| a[:given_name] == 'Josiah' }
    assert second
    assert_equal 'Carberry', second[:family_name]
    assert_equal 'Cool University', second[:affiliation]
    assert 'https://orcid.org/0000-0002-1825-0097', second[:orcid]
    assert_equal 1, second[:pos]

    third = author_meta.detect { |a| a[:given_name] == 'Bert' }
    assert third
    assert_equal 'Droesbeke', third[:family_name]
    assert_nil third[:affiliation]
    assert_equal 'https://orcid.org/0000-0003-0522-5674', third[:orcid]
    assert_equal 2, third[:pos]
  end

  test 'extracts both authors and creators from ro-crate' do
    wf = open_fixture_file('workflows/author_and_creator_test.crate.zip')
    extractor = Seek::WorkflowExtractors::ROCrate.new(wf)
    metadata = extractor.metadata

    assert_equal "Cool University, Dave's Ice Cream Shop", metadata[:other_creators]

    author_meta = metadata[:assets_creators_attributes].values
    assert_equal 4, author_meta.length

    first = author_meta.detect { |a| a[:given_name] == 'Jane' }
    assert first
    assert_equal 'Smith', first[:family_name]
    assert_nil first[:affiliation]
    assert_nil first[:orcid]
    assert_equal 0, first[:pos]

    second = author_meta.detect { |a| a[:given_name] == 'Josiah' }
    assert second
    assert_equal 'Carberry', second[:family_name]
    assert_equal 'Cool University', second[:affiliation]
    assert 'https://orcid.org/0000-0002-1825-0097', second[:orcid]
    assert_equal 1, second[:pos]

    third = author_meta.detect { |a| a[:given_name] == 'Bert' }
    assert third
    assert_equal 'Droesbeke', third[:family_name]
    assert_nil third[:affiliation]
    assert_equal 'https://orcid.org/0000-0003-0522-5674', third[:orcid]
    assert_equal 2, third[:pos]

    fourth = author_meta.detect { |a| a[:given_name] == 'Mittens' }
    assert fourth
    assert_equal 'Smith', fourth[:family_name]
    assert_nil fourth[:affiliation]
    assert_nil fourth[:orcid]
    assert_equal 3, fourth[:pos]
  end
end

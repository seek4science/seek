require 'test_helper'

class NextflowExtractionTest < ActiveSupport::TestCase
  setup do
    @nextflow = WorkflowClass.find_by_key('nextflow') || FactoryBot.create(:nextflow_workflow_class)
  end

  test 'extracts metadata from nextflow config file' do
    wf = open_fixture_file('workflows/ampliseq-nextflow.config')
    extractor = Seek::WorkflowExtractors::Nextflow.new(wf)
    metadata = extractor.metadata

    assert_equal 'nf-core/ampliseq', metadata[:title]
    assert_equal '16S rRNA amplicon sequencing analysis workflow using QIIME2', metadata[:description]

    author_meta = metadata[:assets_creators_attributes].values
    assert_equal 2, author_meta.length

    first = author_meta.detect { |a| a[:given_name] == 'Daniel' }
    assert first
    assert_equal 'Straub', first[:family_name]
    assert_nil first[:affiliation]
    assert_nil first[:orcid]
    assert_equal 0, first[:pos]

    second = author_meta.detect { |a| a[:given_name] == 'Alexander' }
    assert second
    assert_equal 'Peltzer', second[:family_name]
    assert_nil second[:affiliation]
    assert_nil second[:orcid]
    assert_equal 1, second[:pos]

    assert_nil metadata[:other_creators]
  end

  test 'extracts metadata from nextflow workflow RO-Crate' do
    wf = open_fixture_file('workflows/ro-crate-nf-core-ampliseq.crate.zip')
    extractor = Seek::WorkflowExtractors::ROCrate.new(wf)
    metadata = extractor.metadata

    assert_equal 'nf-core/ampliseq', metadata[:title]
    assert_equal '16S rRNA amplicon sequencing analysis workflow using QIIME2', metadata[:description]

    author_meta = metadata[:assets_creators_attributes].values
    assert_equal 2, author_meta.length

    first = author_meta.detect { |a| a[:given_name] == 'Daniel' }
    assert first
    assert_equal 'Straub', first[:family_name]
    assert_nil first[:affiliation]
    assert_nil first[:orcid]
    assert_equal 0, first[:pos]

    second = author_meta.detect { |a| a[:given_name] == 'Alexander' }
    assert second
    assert_equal 'Peltzer', second[:family_name]
    assert_nil second[:affiliation]
    assert_nil second[:orcid]
    assert_equal 1, second[:pos]

    assert_nil metadata[:other_creators]
  end
end

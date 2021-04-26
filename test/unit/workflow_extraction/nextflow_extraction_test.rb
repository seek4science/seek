require 'test_helper'

class NextflowExtractionTest < ActiveSupport::TestCase
  test 'extracts metadata from nextflow config file' do
    wf = open_fixture_file('workflows/ampliseq-nextflow.config')
    extractor = Seek::WorkflowExtractors::Nextflow.new(wf)
    metadata = extractor.metadata

    assert_equal 'nf-core/ampliseq', metadata[:title]
    assert_equal '16S rRNA amplicon sequencing analysis workflow using QIIME2', metadata[:description]
    assert_equal 'Daniel Straub, Alexander Peltzer', metadata[:other_creators]
  end

  test 'extracts metadata from nextflow workflow RO crate' do
    wf = open_fixture_file('workflows/ro-crate-nf-core-ampliseq.crate.zip')
    extractor = Seek::WorkflowExtractors::ROCrate.new(wf)
    metadata = extractor.metadata

    assert_equal 'nf-core/ampliseq', metadata[:title]
    assert_equal '16S rRNA amplicon sequencing analysis workflow using QIIME2', metadata[:description]
    assert_equal 'Daniel Straub, Alexander Peltzer', metadata[:other_creators]
  end
end

require 'test_helper'

class KnimeExtractionTest < ActiveSupport::TestCase
  setup do
    @knime = WorkflowClass.find_by_key('knime') || Factory(:knime_workflow_class)
  end

  test 'can parse KNIME workflow without metadata' do
    wf = open_fixture_file('workflows/no-metadata.knime')
    extractor = Seek::WorkflowExtractors::KNIME.new(wf)

    assert_nothing_raised do
      metadata = extractor.metadata

      assert metadata[:title].blank?
      assert metadata[:description].blank?
      assert_includes metadata[:warnings], 'Unable to determine title of workflow'
    end
  end
end

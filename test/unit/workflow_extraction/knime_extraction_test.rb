require 'test_helper'

class KnimeExtractionTest < ActiveSupport::TestCase
  setup do
    @knime = WorkflowClass.find_by_key('knime') || FactoryBot.create(:knime_workflow_class)
  end

  test 'can parse KNIME workflow without metadata' do
    wf = open_fixture_file('workflows/KNIME_BioBB_Protein_MD_Setup.knwf')
    extractor = Seek::WorkflowExtractors::KNIME.new(wf)

    assert_nothing_raised do
      metadata = extractor.metadata

      assert metadata[:title].blank?
      assert metadata[:description].blank?
    end
  end
end

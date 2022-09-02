require 'test_helper'

class CWLExtractionTest < ActiveSupport::TestCase
  setup do
    @cwl = WorkflowClass.find_by_key('cwl') || Factory(:cwl_workflow_class)
  end

  test 'extracts metadata from packed CWL' do
    wf = open_fixture_file('workflows/rp2-to-rp2path-packed.cwl')
    extractor = Seek::WorkflowExtractors::CWL.new(wf)
    metadata = extractor.metadata
    internals = metadata[:internals]

    assert_equal 5, internals[:inputs].length
    assert_equal 3, internals[:outputs].length
    input = internals[:inputs].detect { |i| i[:id] == '#main/max-steps' }
    assert_equal [{ 'type' => 'int' }, { 'type' => 'null' }], input[:type].sort_by { |t| t['type'] }
  end

  test 'extracts metadata from CWL in workflow RO-Crate' do
    wf = open_fixture_file('workflows/rp2.crate.zip')
    extractor = Seek::WorkflowExtractors::ROCrate.new(wf)
    metadata = extractor.metadata
    internals = metadata[:internals]

    assert_equal 5, internals[:inputs].length
    assert_equal 3, internals[:outputs].length
    input = internals[:inputs].detect { |i| i[:id] == '#main/max-steps' }
    assert_equal [{ 'type' => 'int' }, { 'type' => 'null' }], input[:type].sort_by { |t| t['type'] }
    assert_equal 'RetroPath2.0 IBISBA workflow node', metadata[:title]
    assert_equal "RetroPath2.0 builds a reaction network from a set of source compounds to a set of sink compounds. When applied in a retrosynthetic fashion, the source is composed of the target compounds and the sink is composed of the available reactants (for instance in the context of metabolic engineering the sink is the set of native metabolites of a chassis strain). From amongst all the chemical reactions generated using RetroPath2.0 (in the retrosynthetic way), only a subset may effectively link a source to a subset of sink compounds. This sub-network is considered as a scope and is output in dedicated files.", metadata[:description]
    assert_equal ['workflow', 'knime', 'CWL', 'reaction'].sort, metadata[:tags].sort
    assert_equal 'Thomas Duigou, Stefan Helfrich', metadata[:other_creators]
  end

  test 'structure test' do
    wf = open_fixture_file('workflows/rp2-to-rp2path-packed.cwl')
    extractor = Seek::WorkflowExtractors::CWL.new(wf)
    metadata = extractor.metadata
    internals = metadata[:internals]

    structure = WorkflowInternals::Structure.new(internals)

    assert_equal 5, structure.inputs.count
    assert_equal 3, structure.outputs.count
    assert_equal 2, structure.steps.count
    assert_equal 6, structure.links.count
  end

  test 'generates diagram' do
    wf = open_fixture_file('workflows/with_quotes.cwl')
    extractor = Seek::WorkflowExtractors::CWL.new(wf)
    diagram = extractor.generate_diagram
    assert diagram.length > 100
    assert diagram[0..256].include?('<svg ')
  end
end

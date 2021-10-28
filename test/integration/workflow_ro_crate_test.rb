require 'test_helper'

class WorkflowRoCrateTest < ActionDispatch::IntegrationTest
  include MockHelper
  include HtmlHelper

  test 'parse generated Workflow RO-Crate' do
    project = Factory(:project, title: 'Cool Project')
    person = Factory(:person, first_name: 'Xavier', last_name: 'Xavierson')
    workflow = Factory(:generated_galaxy_ro_crate_workflow, projects: [project], creators: [person], other_creators: 'Jane Bloggs')
    zip = workflow.ro_crate_zip

    crate = ROCrate::WorkflowCrateReader.read_zip(zip)
    jane = crate.get('#Jane Bloggs')
    assert jane
    assert_equal 'Jane Bloggs', jane.name

    workflow = crate.get('Genomics-1-PreProcessing_without_downloading_from_SRA.ga')
    assert workflow
    assert_equal workflow, crate.main_workflow

    diagram = crate.get('Genomics-1-PreProcessing_without_downloading_from_SRA.svg')
    assert diagram
    assert_equal diagram, crate.main_workflow_diagram

    cwl = crate.get('Genomics-1-PreProcessing_without_downloading_from_SRA.cwl')
    assert cwl
    assert_equal cwl, crate.main_workflow_cwl
  end
end
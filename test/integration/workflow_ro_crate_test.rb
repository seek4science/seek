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

  test 'include remotes in generated Workflow RO-Crate' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/little_file.txt", 'http://internet.internet/file'

    workflow = Factory(:local_git_workflow)

    v = workflow.git_version
    assert v.mutable?
    assert_empty v.remote_sources

    assert_difference('Git::Annotation.count', 2) do
      assert_enqueued_jobs(1, only: RemoteGitContentFetchingJob) do
        v.add_remote_file('blah.txt', 'http://internet.internet/file')
        v.add_remote_file('blah2.txt', 'http://internet.internet/another_file', fetch: false)
      end
    end

    RemoteGitContentFetchingJob.perform_now(v, 'blah.txt', 'http://internet.internet/file')

    assert_equal 'http://internet.internet/file', v.remote_sources['blah.txt']
    assert_equal 'http://internet.internet/another_file', v.remote_sources['blah2.txt']
    assert_equal 11, v.get_blob('blah.txt').size
    assert_equal 0, v.get_blob('blah2.txt').size

    zip = workflow.ro_crate_zip

    crate = ROCrate::WorkflowCrateReader.read_zip(zip)
    remote1 = crate.get('http://internet.internet/file')
    assert remote1.is_a?(::ROCrate::File)

    remote1 = crate.get('http://internet.internet/another_file')
    assert remote1.is_a?(::ROCrate::File)
  end
end

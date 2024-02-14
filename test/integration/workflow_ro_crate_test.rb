require 'test_helper'

class WorkflowRoCrateTest < ActionDispatch::IntegrationTest
  include MockHelper
  include HtmlHelper

  test 'parse generated Workflow RO-Crate' do
    project = FactoryBot.create(:project, title: 'Cool Project')
    person = FactoryBot.create(:person, first_name: 'Xavier', last_name: 'Xavierson')
    workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, projects: [project], creators: [person], other_creators: 'Jane Bloggs')
    zip = workflow.ro_crate_zip

    crate = RoCrate::WorkflowCrateReader.read_zip(zip)
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

    workflow = FactoryBot.create(:local_git_workflow)

    v = workflow.git_version
    assert v.mutable?
    assert_empty v.remote_sources

    assert_difference('Git::Annotation.count', 2) do
      assert_enqueued_jobs(1, only: RemoteGitContentFetchingJob) do
        v.add_remote_file('blah.txt', 'http://internet.internet/file')
        v.add_remote_file('blah2.txt', 'http://internet.internet/another_file', fetch: false)
        disable_authorization_checks { v.save! }
      end
    end

    RemoteGitContentFetchingJob.perform_now(v, 'blah.txt')

    assert_equal 'http://internet.internet/file', v.remote_sources['blah.txt']
    assert_equal 'http://internet.internet/another_file', v.remote_sources['blah2.txt']
    assert_equal 11, v.get_blob('blah.txt').size
    assert_equal 0, v.get_blob('blah2.txt').size

    zip = workflow.ro_crate_zip

    crate = RoCrate::WorkflowCrateReader.read_zip(zip)
    remote1 = crate.get('http://internet.internet/file')
    assert remote1.is_a?(::ROCrate::File)

    remote1 = crate.get('http://internet.internet/another_file')
    assert remote1.is_a?(::ROCrate::File)
  end

  test 'generate Workflow RO-Crate for repository containing symlink' do
    git_version = FactoryBot.create(:remote_git_version, ref: 'refs/remotes/heads/symlink',
                          commit: '728337a507db00b8b8ba9979330a4f53d6d43b18')
    assert_nothing_raised do
      zip = git_version.ro_crate_zip

      Zip::File.open(zip) do |zipfile|
        assert zipfile.find_entry('images/workflow-diagram.png').symlink?
        refute zipfile.find_entry('diagram.png').symlink?
      end

      # clean up the ro-crate file
      File.delete(Workflow::Git::Version.find(git_version.id).send(:ro_crate_path))
    end
  end

  test 'generate Workflow RO-Crate when RO-Crate was previously generated' do
    git_version = FactoryBot.create(:remote_git_version)
    git_version = Workflow::Git::Version.find(git_version.id)
    assert_nothing_raised do
      refute File.exist?(git_version.send(:ro_crate_path))
      git_version.ro_crate_zip
      assert File.exist?(git_version.send(:ro_crate_path))
      zip = git_version.ro_crate_zip

      Zip::File.open(zip) do |zipfile|
        assert zipfile.find_entry('README.md')
        assert zipfile.find_entry('concat_two_files.ga')
        assert zipfile.find_entry('ro-crate-metadata.json')
        assert zipfile.find_entry('ro-crate-preview.html')
      end

      # clean up the ro-crate file
      File.delete(git_version.send(:ro_crate_path))
    end
  end

  test 'generate Workflow RO-Crate containing symlink when it was previously generated' do
    git_version = FactoryBot.create(:remote_git_version, ref: 'refs/remotes/heads/symlink',
                          commit: '728337a507db00b8b8ba9979330a4f53d6d43b18')
    git_version = Workflow::Git::Version.find(git_version.id)
    assert_nothing_raised do
      refute File.exist?(git_version.send(:ro_crate_path))
      git_version.ro_crate_zip
      assert File.exist?(git_version.send(:ro_crate_path))
      zip = git_version.ro_crate_zip

      Zip::File.open(zip) do |zipfile|
        assert zipfile.find_entry('LICENSE')
        assert zipfile.find_entry('README.md')
        assert zipfile.find_entry('concat_two_files.ga')
        assert zipfile.find_entry('images/workflow-diagram.png').symlink?
        refute zipfile.find_entry('diagram.png').symlink?
        assert zipfile.find_entry('ro-crate-metadata.json')
        assert zipfile.find_entry('ro-crate-preview.html')
      end

      # clean up the ro-crate file
      File.delete(git_version.send(:ro_crate_path))
    end
  end
end

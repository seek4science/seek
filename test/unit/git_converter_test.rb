require 'test_helper'

class GitConverterTest < ActiveSupport::TestCase
  test 'convert constructed RO-Crate' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow)

    converter = Seek::Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('GitAnnotation.count', 3) do
      assert_difference('GitRepository.count', 1) do
        assert_difference('GitVersion.count', 1) do
          converter.convert(unzip: true)
        end
      end
    end

    assert workflow.local_git_repository
    assert_equal 1, workflow.git_versions.count
    assert workflow.latest_git_version.file_exists?('Genomics-1-PreProcessing_without_downloading_from_SRA.ga')
    assert workflow.latest_git_version.file_exists?('Genomics-1-PreProcessing_without_downloading_from_SRA.cwl')
    assert workflow.latest_git_version.file_exists?('Genomics-1-PreProcessing_without_downloading_from_SRA.svg')
    assert_equal 'Genomics-1-PreProcessing_without_downloading_from_SRA.ga', workflow.latest_git_version.main_workflow_path
    assert_equal 'Genomics-1-PreProcessing_without_downloading_from_SRA.cwl', workflow.latest_git_version.abstract_cwl_path
    assert_equal 'Genomics-1-PreProcessing_without_downloading_from_SRA.svg', workflow.latest_git_version.diagram_path
  end

  test 'convert provided RO-Crate' do
    workflow = Factory(:existing_galaxy_ro_crate_workflow)

    converter = Seek::Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('GitAnnotation.count', 2) do
      assert_difference('GitRepository.count', 1) do
        assert_difference('GitVersion.count', 1) do
          converter.convert(unzip: true)
        end
      end
    end

    assert workflow.local_git_repository
    assert_equal 1, workflow.git_versions.count
    assert workflow.latest_git_version.file_exists?('1-PreProcessing.ga')
    assert workflow.latest_git_version.file_exists?('pp_wf.png')
    assert_equal '1-PreProcessing.ga', workflow.latest_git_version.main_workflow_path
    assert_equal 'pp_wf.png', workflow.latest_git_version.diagram_path
  end
end

require 'test_helper'

class GitConverterTest < ActiveSupport::TestCase
  test 'convert constructed RO-Crate' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow)

    converter = Seek::Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('GitRepository.count', 1) do
      assert_difference('GitVersion.count', 1) do
        converter.convert(unzip: true)
      end
    end

    assert workflow.local_git_repository
    assert_equal 1, workflow.git_versions.count
    assert workflow.latest_git_version.file_exists?('Genomics-1-PreProcessing_without_downloading_from_SRA.cwl')
    assert workflow.latest_git_version.file_exists?('Genomics-1-PreProcessing_without_downloading_from_SRA.ga')
    assert workflow.latest_git_version.file_exists?('Genomics-1-PreProcessing_without_downloading_from_SRA.svg')
  end
end

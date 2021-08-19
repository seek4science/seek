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
    refute workflow.latest_git_version.file_exists?('ro-crate-preview.html')
    assert_equal 'Genomics-1-PreProcessing_without_downloading_from_SRA.ga', workflow.latest_git_version.main_workflow_path
    assert_equal 'Genomics-1-PreProcessing_without_downloading_from_SRA.cwl', workflow.latest_git_version.abstract_cwl_path
    assert_equal 'Genomics-1-PreProcessing_without_downloading_from_SRA.svg', workflow.latest_git_version.diagram_path

    author = workflow.latest_git_version.git_base.lookup(workflow.latest_git_version.commit).author
    assert_equal workflow.contributor.name, author[:name]
    assert_equal workflow.contributor.email, author[:email]
    assert_in_delta workflow.latest_version.created_at.to_time, author[:time], 1.second
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
    assert workflow.latest_git_version.file_exists?('ro-crate-preview.html')
    assert_equal '1-PreProcessing.ga', workflow.latest_git_version.main_workflow_path
    assert_equal 'pp_wf.png', workflow.latest_git_version.diagram_path

    author = workflow.latest_git_version.git_base.lookup(workflow.latest_git_version.commit).author
    assert_equal workflow.contributor.name, author[:name]
    assert_equal workflow.contributor.email, author[:email]
    assert_in_delta workflow.latest_version.created_at.to_time, author[:time], 1.second
  end

  test 'convert provided RO-Crate that has a file with spaces in the path' do
    workflow = Factory(:spaces_ro_crate_workflow)

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
    assert workflow.latest_git_version.file_exists?('biobb_MDsetup_tutorial.ipynb')
    assert workflow.latest_git_version.file_exists?('Protein MD Setup screenshot.png')
    assert_equal 'biobb_MDsetup_tutorial.ipynb', workflow.latest_git_version.main_workflow_path
    assert_equal 'Protein MD Setup screenshot.png', workflow.latest_git_version.diagram_path
  end

  test 'convert workflow that is just a single file' do
    workflow = Factory(:cwl_workflow)

    converter = Seek::Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('GitAnnotation.count', 1) do
      assert_difference('GitRepository.count', 1) do
        assert_difference('GitVersion.count', 1) do
          converter.convert(unzip: true)
        end
      end
    end

    assert workflow.local_git_repository
    assert_equal 1, workflow.git_versions.count
    assert workflow.latest_git_version.file_exists?('rp2-to-rp2path.cwl')
    assert_equal 'rp2-to-rp2path.cwl', workflow.latest_git_version.main_workflow_path
  end

  test 'convert workflow that is a remote file' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'https://www.abc.com/workflow.cwl'
    workflow = Factory(:cwl_url_workflow)

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
    assert workflow.latest_git_version.file_exists?('rp2-to-rp2path.cwl')
    assert_equal 'rp2-to-rp2path.cwl', workflow.latest_git_version.main_workflow_path
    ann = workflow.latest_git_version.find_git_annotations('remote_source')
    assert_equal 1, ann.length
    assert_equal 'rp2-to-rp2path.cwl', ann.first.path
    assert_equal 'https://www.abc.com/workflow.cwl', ann.first.value
    assert_equal 'https://www.abc.com/workflow.cwl', workflow.latest_git_version.remote_sources['rp2-to-rp2path.cwl']
  end
end

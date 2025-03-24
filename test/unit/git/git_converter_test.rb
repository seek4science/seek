require 'test_helper'

class GitConverterTest < ActiveSupport::TestCase
  test 'convert constructed RO-Crate' do
    workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 3) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
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
    workflow = FactoryBot.create(:existing_galaxy_ro_crate_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 2) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
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
    workflow = FactoryBot.create(:spaces_ro_crate_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 2) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
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
    workflow = FactoryBot.create(:cwl_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 1) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
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
    workflow = FactoryBot.create(:cwl_url_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 2) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
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

  test 'ensure version metadata is ported correctly' do
    workflow = FactoryBot.create(:cwl_workflow, license: 'CC0-1.0',
                       title: 'First Title',
                       description: '123',
                       maturity_level: :work_in_progress,
                       other_creators: 'Dave')
    v1 = workflow.latest_version
    v2 = nil
    disable_authorization_checks do
      v1.update(visibility: :private)
      FactoryBot.create(:cwl_content_blob, asset: workflow, asset_version: 2)
      workflow.save_as_new_version
      v2 = workflow.latest_version
      v2.update(doi: '10.81082/dev-workflowhub.workflow.136.1',
                           license: 'CC-BY-4.0',
                           title: 'Second Title',
                           description: 'abcxyz',
                           maturity_level: :released,
                           visibility: :public,
                           other_creators: 'Steve')
    end

    converter = Git::Converter.new(workflow)
    assert_difference('Git::Version.count', 2) do
      converter.convert(unzip: true)
    end

    assert workflow.local_git_repository
    assert_equal 2, workflow.git_versions.count
    gv1 = workflow.git_versions.first
    gv2 = workflow.git_versions.last

    assert_nil v1.doi
    assert_equal 'CC0-1.0', gv1.license
    assert_equal 'First Title', gv1.title
    assert_equal '123', gv1.description
    assert_equal 'Dave', gv1.other_creators
    assert_equal :work_in_progress, gv1.maturity_level
    assert_equal :private, gv1.visibility
    refute gv1.mutable?

    assert_equal '10.81082/dev-workflowhub.workflow.136.1', gv2.doi
    assert_equal 'CC-BY-4.0', gv2.license
    assert_equal 'Second Title', gv2.title
    assert_equal 'abcxyz', gv2.description
    assert_equal 'Steve', gv2.other_creators
    assert_equal :released, gv2.maturity_level
    assert_equal :public, gv2.visibility
    assert gv2.mutable?

    keys = gv2.resource_attributes.keys.map(&:to_s)
    assert_not_includes keys, 'id'
    assert_not_includes keys, 'created_at'
    assert_not_includes keys, 'updated_at'
    assert_not_includes keys, 'version'
    assert_not_includes keys, 'doi'
  end

  test 'convert provided RO-Crate that has a file with dots in the path' do
    workflow = FactoryBot.create(:dots_ro_crate_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 1) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
          converter.convert(unzip: true)
        end
      end
    end

    assert workflow.local_git_repository
    assert_equal 1, workflow.git_versions.count
    assert workflow.latest_git_version.file_exists?('ont-artic-variation.ga')
    assert workflow.latest_git_version.file_exists?('.dockstore.yml')
    assert_equal 'ont-artic-variation.ga', workflow.latest_git_version.main_workflow_path
    assert_nothing_raised do
      workflow.ro_crate_zip
    end
  end

  test 'safely re-run conversion process without creating additional records' do
    workflow = FactoryBot.create(:existing_galaxy_ro_crate_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 2) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
          converter.convert(unzip: true)
        end
      end
    end

    assert_no_difference('Git::Annotation.count') do
      assert_no_difference('Git::Repository.count') do
        assert_no_difference('Git::Version.count') do
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

  test 're-run conversion process and overwrite previous records' do
    workflow = FactoryBot.create(:existing_galaxy_ro_crate_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 2) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
          converter.convert(unzip: true)
        end
      end
    end

    repo = workflow.local_git_repository
    gv = workflow.git_version

    assert_no_difference('Git::Annotation.count') do
      assert_no_difference('Git::Repository.count') do
        assert_no_difference('Git::Version.count') do
          converter.convert(unzip: true, overwrite: true)
        end
      end
    end

    assert_not_equal repo.id, workflow.reload.local_git_repository.id
    assert_not_equal gv.id, workflow.reload.git_version.id

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

  test 'converted workflow does not retain original files from RO-Crate' do
    workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow)

    converter = Git::Converter.new(workflow)

    refute workflow.local_git_repository
    refute workflow.latest_git_version

    assert_difference('Git::Annotation.count', 3) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Git::Version.count', 1) do
          converter.convert(unzip: true)
        end
      end
    end

    assert_difference('Git::Annotation.count', -1) do
      workflow.git_version.remove_file('Genomics-1-PreProcessing_without_downloading_from_SRA.cwl')
    end

    refute workflow.ro_crate.entries.key?('Genomics-1-PreProcessing_without_downloading_from_SRA.cwl')
    assert workflow.ro_crate.entries.key?('Genomics-1-PreProcessing_without_downloading_from_SRA.ga')
  end
end

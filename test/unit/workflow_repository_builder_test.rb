require 'test_helper'

class WorkflowRepositoryBuilderTest < ActiveSupport::TestCase
  setup do
    @galaxy = WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class)
  end

  test 'builds local file crate repository' do
    params = { main_workflow: { data: fixture_file_upload('workflows/1-PreProcessing.ga') },
               diagram: { data: fixture_file_upload('file_picture.png') },
               abstract_cwl: { data: fixture_file_upload('workflows/rp2-to-rp2path-packed.cwl') }
    }
    builder = WorkflowRepositoryBuilder.new(params)
    builder.workflow_class = @galaxy
    workflow = builder.build
    assert workflow
    assert workflow.local_git_repository
    assert workflow.git_version
    assert workflow.git_version.file_exists?('1-PreProcessing.ga')
    assert workflow.git_version.file_exists?('file_picture.png')
    assert workflow.git_version.file_exists?('rp2-to-rp2path-packed.cwl')
  end

  test 'builds remote file crate repository' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/1-PreProcessing.ga", 'http://workflow.com/1.ga'
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { main_workflow: { data_url: 'http://workflow.com/1.ga' },
               diagram: { data_url: 'http://somewhere.com/piccy.png' },
               abstract_cwl: { data_url: 'http://workflow.com/rp2.cwl' }
    }
    builder = WorkflowRepositoryBuilder.new(params)
    builder.workflow_class = @galaxy
    workflow = builder.build
    assert workflow
    assert workflow.local_git_repository
    assert workflow.git_version
    assert workflow.git_version.file_exists?('1.ga')
    assert workflow.git_version.file_exists?('piccy.png')
    assert workflow.git_version.file_exists?('rp2.cwl')
  end

  test 'reports error with missing workflow' do
    params = { diagram: { data: fixture_file_upload('file_picture.png') },
               abstract_cwl: { data: fixture_file_upload('workflows/rp2-to-rp2path-packed.cwl') }
    }
    builder = WorkflowRepositoryBuilder.new(params)
    refute builder.valid?
    assert builder.errors.any?
    assert builder.errors[:main_workflow].join.include?('blank')
  end

  test 'reports error with missing workflow params' do
    params = { main_workflow: { bla: true },
               diagram: { data: fixture_file_upload('file_picture.png') },
               abstract_cwl: { data: fixture_file_upload('workflows/rp2-to-rp2path-packed.cwl') }
    }
    builder = WorkflowRepositoryBuilder.new(params)
    refute builder.valid?
    assert builder.errors.any?
    assert builder.errors[:main_workflow].join.include?('file or remote')
  end

  test 'reports errors with resolving remote refs' do
    stub_request(:head, 'http://workflow.com/1.ga').to_return(status: 200)
    stub_request(:get, 'http://workflow.com/1.ga').to_return(body: 'ERROR', status: 500)
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { main_workflow: { data_url: 'http://workflow.com/1.ga' },
               diagram: { data_url: 'http://somewhere.com/piccy.png' },
               abstract_cwl: { data_url: 'http://workflow.com/rp2.cwl' }
    }
    builder = WorkflowRepositoryBuilder.new(params)
    refute builder.valid?
    assert builder.errors.any?
    assert builder.errors[:main_workflow].join.include?('URL could not be accessed')
  end

  test 'does not create spurious entities' do
    params = { main_workflow: { data: fixture_file_upload('workflows/1-PreProcessing.ga') },
               diagram: { data: fixture_file_upload('file_picture.png') },
               abstract_cwl: { data: fixture_file_upload('workflows/rp2-to-rp2path-packed.cwl') }
    }
    builder = WorkflowRepositoryBuilder.new(params)
    builder.workflow_class = @galaxy
    workflow = builder.build
    workflow.title = "Test"
    workflow.projects = [FactoryBot.create(:project)]
    disable_authorization_checks { workflow.save }
    crate = workflow.ro_crate

    assert_equal 19, crate.entities.count
    assert crate.get("ro-crate-metadata.json").is_a?(ROCrate::Metadata)
    assert crate.get("ro-crate-preview.html").is_a?(ROCrate::Preview)
    assert crate.get("./").is_a?(ROCrate::WorkflowCrate)
    assert crate.get("1-PreProcessing.ga").is_a?(ROCrate::Workflow)
    assert crate.get("file_picture.png").is_a?(ROCrate::WorkflowDiagram)
    assert crate.get("rp2-to-rp2path-packed.cwl").is_a?(ROCrate::WorkflowDescription)
    assert crate.get("#galaxy").is_a?(ROCrate::ContextualEntity)
    assert crate.get("#cwl").is_a?(ROCrate::ContextualEntity)
    assert 9, crate.entities.select { |e| e.type == 'FormalParameter' }.count
    assert crate.get(ROCrate::WorkflowCrate::PROFILE['@id']).is_a?(ROCrate::ContextualEntity)
  end
end

require 'test_helper'

class WorkflowROCrateBuilderTest < ActiveSupport::TestCase

  test 'builds local file crate' do
    params = { workflow: { data: fixture_file_upload('files/workflows/1-PreProcessing.ga') },
               diagram: { data: fixture_file_upload('files/file_picture.png') },
               abstract_cwl: { data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl') }
    }
    builder = WorkflowCrateBuilder.new(params)
    builder.workflow_extractor = Seek::WorkflowExtractors::Galaxy
    cb_params = builder.build
    assert cb_params[:tmp_io_object].respond_to?(:read), 'tmp_io_object missing or not readable?'
    assert cb_params[:file_size] > 100, "Crate file size unexpectedly small: #{cb_params[:file_size]}"
    assert_equal 'new-workflow.basic.crate.zip', cb_params[:original_filename]
    assert_equal 'application/zip', cb_params[:content_type]
    assert_equal true, cb_params[:make_local_copy]
  end

  test 'builds remote file crate' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/1-PreProcessing.ga", 'http://workflow.com/1.ga'
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { workflow: { data_url: 'http://workflow.com/1.ga' },
               diagram: { data_url: 'http://somewhere.com/piccy.png' },
               abstract_cwl: { data_url: 'http://workflow.com/rp2.cwl' }
    }
    builder = WorkflowCrateBuilder.new(params)
    builder.workflow_extractor = Seek::WorkflowExtractors::Galaxy
    cb_params = builder.build
    assert cb_params[:tmp_io_object].respond_to?(:read), 'tmp_io_object missing or not readable?'
    assert cb_params[:file_size] > 100, "Crate file size unexpectedly small: #{cb_params[:file_size]}"
    assert_equal 'new-workflow.basic.crate.zip', cb_params[:original_filename]
    assert_equal 'application/zip', cb_params[:content_type]
    assert_equal true, cb_params[:make_local_copy]
  end

  test 'reports error with missing workflow' do
    params = { diagram: { data: fixture_file_upload('files/file_picture.png') },
               abstract_cwl: { data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl') }
    }
    builder = WorkflowCrateBuilder.new(params)
    refute builder.valid?
    assert builder.errors.any?
    assert builder.errors[:workflow].join.include?('blank')
  end

  test 'reports error with missing workflow params' do
    params = { workflow: { bla: true },
               diagram: { data: fixture_file_upload('files/file_picture.png') },
               abstract_cwl: { data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl') }
    }
    builder = WorkflowCrateBuilder.new(params)
    refute builder.valid?
    assert builder.errors.any?
    assert builder.errors[:workflow].join.include?('file or remote')
  end

  test 'reports errors with resolving remote refs' do
    stub_request(:head, 'http://workflow.com/1.ga').to_return(status: 200)
    stub_request(:get, 'http://workflow.com/1.ga').to_return(body: 'ERROR', status: 500)
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { workflow: { data_url: 'http://workflow.com/1.ga' },
               diagram: { data_url: 'http://somewhere.com/piccy.png' },
               abstract_cwl: { data_url: 'http://workflow.com/rp2.cwl' }
    }
    builder = WorkflowCrateBuilder.new(params)
    refute builder.valid?
    assert builder.errors.any?
    assert builder.errors[:workflow].join.include?('URL could not be accessed')
  end
end

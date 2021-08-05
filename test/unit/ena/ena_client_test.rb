require 'test_helper'
require 'zip'

class EnaClientTest < ActiveSupport::TestCase

  setup do
    @ena_client = Ena::EnaClient.new
    @project = Factory(:project)
    project_ids = [@project.id]
    ena_run_sample_type = Factory(:simple_sample_type, id: 1, project_ids: project_ids)
    ena_experiment_sample_type = Factory(:simple_sample_type, id: 2, project_ids: project_ids)
    ena_study_sample_type = Factory(:simple_sample_type, id: 3, project_ids: project_ids)
    ena_sample_sample_type = Factory(:simple_sample_type, id: 4, project_ids: project_ids)
  end

  test 'generate tsv files' do
    res = @ena_client.generate_ena_tsv @project.id
    assert_equal ".zip", File.extname(res)
    Zip::File.open(res) do |zip_file|
      zip_file.each do |f|
        assert_equal ".tsv",  File.extname(f.name)
      end
    end
  end

  test 'cleanup temp folder' do
    res = @ena_client.generate_ena_tsv @project.id
    folder = File.join(Dir.tmpdir, 'seek-tmp', 'zip-files', File.basename(res, ".*"))
    assert_equal false, File.directory?(folder)
  end

end

require 'test_helper'

class UnzipDataFileJobTest < ActiveSupport::TestCase

  def setup
    @person = FactoryBot.create(:project_administrator)
    User.current_user = @person.user
    @project_id = @person.projects.first.id

    @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:zip_folder_content_blob),
                         policy: FactoryBot.create(:private_policy), contributor: @person
    assert_empty @data_file.unzipped_files
  end

  test 'unzip datafile' do
    @data_file.policy = FactoryBot.create(:public_policy)
    disable_authorization_checks{@data_file.save!}
    job = UnzipDataFileJob.new
    assert_no_difference('DataFile.count') do
      job.perform(@data_file)
    end
    unzipped = job.unzipper.fetch
    assert_equal 2, unzipped.count
    unzipped.each do |zipped_file|
      assert_equal @data_file.project_ids, zipped_file.project_ids
      assert_equal @person, zipped_file.contributor
      assert_equal @data_file.id, zipped_file.zip_origin_id
    end
  end

  test 'records exception' do
    class FailingUnzipDataFileJob < UnzipDataFileJob
      def perform(data_file)
        raise 'critical error'
      end
    end

    FailingUnzipDataFileJob.perform_now(@data_file)

    task = @data_file.unzip_task
    assert task.failed?
    refute_nil task.exception

    # contains message and backtrace
    assert_match /critical error/, task.exception
    assert_match /block in perform_now/, task.exception
    assert_match /activejob/, task.exception

  end

end

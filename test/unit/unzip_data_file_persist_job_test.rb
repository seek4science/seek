require 'test_helper'

class UnzipDataFilePersistJobTest < ActiveSupport::TestCase
  def setup
    create_sample_attribute_type
    @person = FactoryBot.create(:project_administrator)
    User.with_current_user(@person.user) do
	    @project_id = @person.projects.first.id

	    @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:zip_folder_content_blob),
		                             policy: FactoryBot.create(:private_policy), contributor: @person
	end
  end

  test 'queue job' do
    assert_enqueued_jobs(1, only: UnzipDataFilePersistJob) do
      UnzipDataFilePersistJob.new(@data_file, @person.user).queue_job
    end
    @data_file.reload
    assert_equal Task::STATUS_QUEUED, @data_file.unzip_persistence_task.status
  end

  test 'persists unzip' do
    @data_file.policy = FactoryBot.create(:public_policy, permissions: [FactoryBot.create(:edit_permission)])
    disable_authorization_checks{@data_file.save!}
    assert_difference('DataFile.count', 2) do
      assert_difference('Policy.count', 2) do
        assert_difference('Permission.count', 2) do
          assert_difference('ReindexingQueue.count', 2) do
            assert_difference('AuthLookupUpdateQueue.count', 2) do
              with_config_value(:auth_lookup_enabled, true) do # needed to test added to queue
                UnzipDataFilePersistJob.perform_now(@data_file, @person.user)
              end
            end
          end
        end
      end
    end

    @data_file.reload

    assert_equal Task::STATUS_DONE, @data_file.unzip_persistence_task.status

    assert_equal 2, @data_file.unzipped_files.count

    unzipped = @data_file.unzipped_files

    unzipped.each do |unzipped_file|
      assert_equal @person, unzipped_file.contributor
      assert_equal [@project_id], unzipped_file.project_ids
      assert_equal @person, unzipped_file.contributor
      assert_equal Policy::MANAGING, unzipped_file.policy.access_type
      assert_equal 1, unzipped_file.policy.permissions.count
      assert_equal Policy::EDITING, unzipped_file.policy.permissions.first.access_type
    end

    #check the policy and permissions are all uniq and not referencing each other
    refute_equal @data_file.policy_id, unzipped.first.policy_id
    policy_ids = unzipped.collect { |u| u.policy.id }
    permission_ids = unzipped.collect { |u| u.policy.permissions.first.id }
    assert_equal 2, policy_ids.count
    assert_equal policy_ids, policy_ids.uniq
    assert_equal 2, permission_ids.count
    assert_equal permission_ids, permission_ids.uniq
  end

  test 'persists unzip and associate with assay' do
    assay_asset1 = FactoryBot.create(:assay_asset, asset: @data_file, direction: AssayAsset::Direction::INCOMING,
                                         assay: FactoryBot.create(:assay, contributor: @person))
    assay_asset2 = FactoryBot.create(:assay_asset, asset: @data_file, direction: AssayAsset::Direction::OUTGOING,
                                         assay: FactoryBot.create(:assay, contributor: @person))

    assert_difference('AssayAsset.count', 2) do
      assert_difference('DataFile.count', 2) do
        UnzipDataFilePersistJob.perform_now(@data_file, @person.user, assay_ids: [assay_asset1.assay_id])
      end
    end

    @data_file.reload
    @data_file.unzipped_files.each do |unzipped_file|
      assert_equal [assay_asset1.assay], unzipped_file.assays
      assert_equal assay_asset1.direction, unzipped_file.assay_assets.first.direction
    end
  end

  test 'records exception' do
    class FailingUnzipDataFilePersistJob < UnzipDataFilePersistJob
      def perform(data_file, user, assay_ids: nil)
        raise 'critical error'
      end
    end

    FailingUnzipDataFilePersistJob.perform_now(@data_file, @person.user)

    task = @data_file.unzip_persistence_task
    assert task.failed?
    refute_nil task.exception

    # contains message and backtrace
    assert_match /critical error/, task.exception
    assert_match /block in perform_now/, task.exception
    assert_match /activejob/, task.exception

  end
end

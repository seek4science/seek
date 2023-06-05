require 'test_helper'

class RdfGenerationJobTest < ActiveSupport::TestCase
  test 'rdf generation job created after save' do
    item = nil

    assert_enqueued_jobs(1, only: RdfGenerationJob) do
      assert_difference('RdfGenerationQueue.count', 1) do
        item = FactoryBot.create :project
        assert RdfGenerationQueue.last.refresh_dependents
      end
    end

    RdfGenerationQueue.delete_all

    assert_enqueued_jobs(1, only: RdfGenerationJob) do
      assert_difference('RdfGenerationQueue.count', 1) do
        item.title = 'sdfhsdfkhsdfklsdf2'
        disable_authorization_checks { item.save! }
      end
    end

    # check a new job isn't created when nothing has changed
    item = FactoryBot.create :model
    disable_authorization_checks { item.save! }
    assert_no_enqueued_jobs(only: RdfGenerationJob) do
      assert_no_difference('RdfGenerationQueue.count') do
        disable_authorization_checks { item.save! }
      end
    end
  end

  test 'rdf generation job created after policy change' do
    item = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    RdfGenerationQueue.delete_all

    item.policy.access_type = Policy::NO_ACCESS
    disable_authorization_checks do
      assert_enqueued_jobs(1, only: RdfGenerationJob) do
        assert_difference('RdfGenerationQueue.count', 1) do
          item.policy.save!
          refute RdfGenerationQueue.last.refresh_dependents
        end
      end
    end
  end

  test 'rdf generation job not created after policy change for non rdf supported entity' do
    item = FactoryBot.create(:event, policy: FactoryBot.create(:public_policy))
    RdfGenerationQueue.delete_all

    item.policy.access_type = Policy::NO_ACCESS
    disable_authorization_checks do
      assert_no_enqueued_jobs(only: RdfGenerationJob) do
        assert_no_difference('RdfGenerationQueue.count') do
          item.policy.save!
        end
      end
    end
  end

  test 'create job' do
    item = FactoryBot.create(:assay)

    assert_enqueued_jobs(1, only: RdfGenerationJob) do
      RdfGenerationJob.new.queue_job
    end
  end

  test 'skip items that dont support rdf' do
    item = FactoryBot.create(:event)
    refute item.rdf_supported?
    refute RdfGenerationQueue.where(item_id: item.id, item_type: 'Event').exists?

    item = FactoryBot.create(:sop)
    assert item.rdf_supported?
    assert RdfGenerationQueue.where(item_id: item.id, item_type: 'Sop').exists?
  end

  test 'perform' do
    item = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    RdfGenerationQueue.delete_all

    expected_rdf_file = File.join(Rails.root, 'tmp/testing-filestore/rdf/public', "Assay-test-#{item.id}.rdf")
    assert_equal expected_rdf_file, item.rdf_storage_path
    FileUtils.rm expected_rdf_file if File.exist?(expected_rdf_file)
    RdfGenerationQueue.enqueue(item, queue_job: false)
    job = RdfGenerationJob.new
    assert_difference('RdfGenerationQueue.count', -1) do
      job.perform
    end

    assert File.exist?(expected_rdf_file)
    rdf = ''
    open(expected_rdf_file) do |f|
      rdf = f.read
    end
    assert_equal item.to_rdf, rdf
    FileUtils.rm expected_rdf_file
    refute File.exist?(expected_rdf_file)
  end

  test 'should not allow duplicates' do
    assay = FactoryBot.create(:assay)
    RdfGenerationQueue.delete_all
    refute RdfGenerationQueue.where(item_type: 'Assay', item_id: assay).exists?
    assert_difference('RdfGenerationQueue.count', 1) do
      RdfGenerationQueue.enqueue(assay)
    end

    assert_no_difference('RdfGenerationQueue.count') do
      RdfGenerationQueue.enqueue(assay)
    end
  end

  test 'should not set `refresh_dependents` to false for existing queue item' do
    assay = FactoryBot.create(:assay)
    RdfGenerationQueue.delete_all
    RdfGenerationQueue.enqueue(assay, refresh_dependents: true)
    assert RdfGenerationQueue.where(item_type: 'Assay', item_id: assay, refresh_dependents: true).exists?

    assert_no_difference('RdfGenerationQueue.count') do
      RdfGenerationQueue.enqueue(assay, refresh_dependents: false)
    end
    assert RdfGenerationQueue.where(item_type: 'Assay', item_id: assay).first.refresh_dependents
  end

  test 'should set `refresh_dependents` to true for existing queue item' do
    assay = FactoryBot.create(:assay)
    RdfGenerationQueue.delete_all
    RdfGenerationQueue.enqueue(assay, refresh_dependents: false)
    assert RdfGenerationQueue.where(item_type: 'Assay', item_id: assay, refresh_dependents: false).exists?

    assert_no_difference('RdfGenerationQueue.count') do
      RdfGenerationQueue.enqueue(assay, refresh_dependents: true)
    end
    assert RdfGenerationQueue.where(item_type: 'Assay', item_id: assay).first.refresh_dependents
  end
end

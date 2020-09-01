require 'test_helper'

class RdfGenerationJobTest < ActiveSupport::TestCase
  def setup
    Delayed::Job.delete_all
  end

  def teardown
    Delayed::Job.delete_all
  end

  test 'rdf generation job created after save' do
    item = nil

    assert_difference('Delayed::Job.count', 2) do
      assert_difference('RdfGenerationQueue.count', 1) do
        item = Factory :project
        assert RdfGenerationQueue.last.refresh_dependents
      end
    end
    handlers = Delayed::Job.all.collect(&:handler).join(',')
    assert_includes(handlers, 'RdfGenerationJob')

    Delayed::Job.delete_all # necessary, otherwise the next assert will fail since it won't create a new job if it already exists as pending
    RdfGenerationQueue.delete_all

    assert_difference('Delayed::Job.count', 2) do
      assert_difference('RdfGenerationQueue.count', 1) do
        item.title = 'sdfhsdfkhsdfklsdf2'
        disable_authorization_checks { item.save! }
      end
    end
    handlers = Delayed::Job.all.collect(&:handler).join(',')
    assert_includes(handlers, 'RdfGenerationJob')

    # check a new job isn't created when nothing (except the last used timestamp) has changed
    item = Factory :model
    disable_authorization_checks { item.save! }
    item.last_used_at = Time.now
    assert_no_difference('Delayed::Job.count') do
      assert_no_difference('RdfGenerationQueue.count') do
        disable_authorization_checks { item.save! }
      end
    end
  end

  test 'rdf generation job created after policy change' do
    item = Factory(:sop, policy: Factory(:public_policy))
    Delayed::Job.delete_all
    RdfGenerationQueue.delete_all

    handlers = Delayed::Job.all.collect(&:handler).join(',')
    refute_includes(handlers, 'RdfGenerationJob')

    item.policy.access_type = Policy::NO_ACCESS
    disable_authorization_checks do
      assert_difference('Delayed::Job.count', 1) do
        assert_difference('RdfGenerationQueue.count', 1) do
          item.policy.save!
          refute RdfGenerationQueue.last.refresh_dependents
        end
      end
    end

    handlers = Delayed::Job.all.collect(&:handler).join(',')
    assert_includes(handlers, 'RdfGenerationJob')
  end

  test 'rdf generation job not created after policy change for non rdf supported entity' do
    item = Factory(:event, policy: Factory(:public_policy))
    Delayed::Job.delete_all
    RdfGenerationQueue.delete_all

    handlers = Delayed::Job.all.collect(&:handler).join(',')
    refute_includes(handlers, 'RdfGenerationJob')

    item.policy.access_type = Policy::NO_ACCESS
    disable_authorization_checks do
      assert_no_difference('Delayed::Job.count') do
        assert_no_difference('RdfGenerationQueue.count') do
          item.policy.save!
        end
      end
    end

    handlers = Delayed::Job.all.collect(&:handler).join(',')
    refute_includes(handlers, 'RdfGenerationJob')
  end

  test 'create job' do
    item = Factory(:assay)

    Delayed::Job.delete_all

    assert_difference('Delayed::Job.count', 1) do
      RdfGenerationJob.new.queue_job
    end
    job = Delayed::Job.last
    assert_equal 2, job.priority
  end

  test 'skip items that dont support rdf' do
    item = Factory(:event)
    refute item.rdf_supported?
    refute RdfGenerationQueue.where(item_id: item.id, item_type: 'Event').exists?

    item = Factory(:sop)
    assert item.rdf_supported?
    assert RdfGenerationQueue.where(item_id: item.id, item_type: 'Sop').exists?
  end

  test 'perform' do
    item = Factory(:assay, policy: Factory(:public_policy))
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
    assay = Factory(:assay)
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
    assay = Factory(:assay)
    RdfGenerationQueue.delete_all
    RdfGenerationQueue.enqueue(assay, refresh_dependents: true)
    assert RdfGenerationQueue.where(item_type: 'Assay', item_id: assay, refresh_dependents: true).exists?

    assert_no_difference('RdfGenerationQueue.count') do
      RdfGenerationQueue.enqueue(assay, refresh_dependents: false)
    end
    assert RdfGenerationQueue.where(item_type: 'Assay', item_id: assay).first.refresh_dependents
  end

  test 'should set `refresh_dependents` to true for existing queue item' do
    assay = Factory(:assay)
    RdfGenerationQueue.delete_all
    RdfGenerationQueue.enqueue(assay, refresh_dependents: false)
    assert RdfGenerationQueue.where(item_type: 'Assay', item_id: assay, refresh_dependents: false).exists?

    assert_no_difference('RdfGenerationQueue.count') do
      RdfGenerationQueue.enqueue(assay, refresh_dependents: true)
    end
    assert RdfGenerationQueue.where(item_type: 'Assay', item_id: assay).first.refresh_dependents
  end
end

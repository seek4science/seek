require 'test_helper'

class AuthLookupJobTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled = true
    AuthLookupUpdateQueue.destroy_all
    Delayed::Job.destroy_all
  end

  def teardown
    Seek::Config.auth_lookup_enabled = @val
  end

  test 'exists' do
    assert !AuthLookupUpdateJob.new.exists?
    assert_difference('Delayed::Job.count', 1) do
      Delayed::Job.enqueue AuthLookupUpdateJob.new
    end

    assert AuthLookupUpdateJob.new.exists?
    job = Delayed::Job.first

    assert_nil job.failed_at
    job.failed_at = Time.now
    job.save!
    assert !AuthLookupUpdateJob.new.exists?, 'Should ignore failed jobs'

    assert_nil job.locked_at
    job.locked_at = Time.now
    job.failed_at = nil
    job.save!
    assert !AuthLookupUpdateJob.new.exists?, 'Should ignore locked jobs'
  end

  test 'count' do
    assert_equal 0, AuthLookupUpdateJob.new.count

    Delayed::Job.enqueue AuthLookupUpdateJob.new

    assert_equal 1, AuthLookupUpdateJob.new.count

    job = Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert_equal 0, AuthLookupUpdateJob.new.count, 'Should ignore locked jobs'
    assert_equal 1, AuthLookupUpdateJob.new.count(false), 'Should not ignore locked jobs when requested'
  end

  test 'add items to queue' do
    sop = Factory :sop
    data = Factory :data_file

    # need to clear the queue for items added through callbacks in the creation of the test items
    AuthLookupUpdateQueue.destroy_all
    Delayed::Job.destroy_all

    assert_difference('Delayed::Job.count', 1) do
      assert_difference('AuthLookupUpdateQueue.count', 2) do
        AuthLookupUpdateJob.new.add_items_to_queue [sop, data, sop]
      end
    end

    assert_equal [data, sop], AuthLookupUpdateQueue.all.collect(&:item).sort_by { |i| i.class.name }

    AuthLookupUpdateQueue.destroy_all
    Delayed::Job.destroy_all
    assert_difference('Delayed::Job.count', 1) do
      assert_difference('AuthLookupUpdateQueue.count', 1) do
        AuthLookupUpdateJob.new.add_items_to_queue nil
      end
    end
    assert_nil AuthLookupUpdateQueue.first.item
  end

  test 'perform' do
    Sop.delete_all
    user = Factory :user
    other_user = Factory :user
    sop = Factory :sop, contributor: user, policy: Factory(:editing_public_policy)
    AuthLookupUpdateQueue.destroy_all
    AuthLookupUpdateJob.new.add_items_to_queue sop
    Sop.clear_lookup_table

    assert_difference('AuthLookupUpdateQueue.count', -1) do
      AuthLookupUpdateJob.new.perform
    end

    c = ActiveRecord::Base.connection.select_one('select count(*) from sop_auth_lookup;').values[0].to_i
    #+1 to User count to include anonymous user
    assert_equal User.count + 1, c

    assert Sop.lookup_table_consistent?(user.id)
    assert Sop.lookup_table_consistent?(other_user.id)
  end

  test 'takes items from queue according to batch size configuration' do
    sop = Factory(:sop)
    20.times do
      AuthLookupUpdateQueue.create(item: sop, priority: 0)
    end

    with_config_value(:auth_lookup_update_batch_size, 3) do
      assert_difference('AuthLookupUpdateQueue.count', -3) do
        AuthLookupUpdateJob.new.perform
      end
    end

    with_config_value(:auth_lookup_update_batch_size, 7) do
      assert_difference('AuthLookupUpdateQueue.count', -7) do
        AuthLookupUpdateJob.new.perform
      end
    end
  end
end

require 'test_helper'

class AuthLookupUpdateQueueTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled=true
    AuthLookupUpdateQueue.destroy_all
    Delayed::Job.destroy_all
  end

  def teardown
    Seek::Config.auth_lookup_enabled=@val
  end

  test "exists" do
    sop = Factory :sop
    model = Factory :model
    AuthLookupUpdateQueue.destroy_all
    assert !AuthLookupUpdateQueue.exists?(sop)
    assert !AuthLookupUpdateQueue.exists?(model)
    assert !AuthLookupUpdateQueue.exists?(nil)

    disable_authorization_checks do
      AuthLookupUpdateQueue.create :item=>sop
    end

    assert AuthLookupUpdateQueue.exists?(sop)
    assert !AuthLookupUpdateQueue.exists?(model)
    assert !AuthLookupUpdateQueue.exists?(nil)

    AuthLookupUpdateQueue.create :item=>nil

    assert AuthLookupUpdateQueue.exists?(sop)
    assert !AuthLookupUpdateQueue.exists?(model)
    assert AuthLookupUpdateQueue.exists?(nil)
  end
end

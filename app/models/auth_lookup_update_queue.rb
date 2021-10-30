class AuthLookupUpdateQueue < ApplicationRecord
  include ResourceQueue

  def self.dequeue(num = Seek::Config.auth_lookup_update_batch_size)
    super(num)
  end

  def self.queue_enabled?
    Seek::Config.auth_lookup_enabled
  end

  def self.job_class
    AuthLookupUpdateJob
  end
end

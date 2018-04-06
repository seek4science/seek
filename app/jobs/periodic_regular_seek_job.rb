# overrides relevant to all job types that run regularly with a delay
module PeriodicRegularSeekJob

  def follow_on_job?
    true
  end

  def exists?(ignore_locked = false)
    super(ignore_locked)
  end

  def count(ignore_locked = false)
    super(ignore_locked)
  end
end

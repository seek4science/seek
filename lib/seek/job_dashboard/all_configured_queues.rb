module Seek
  module JobDashboard
    # Mission Control derives its queue list from SolidQueue::Queue.all, which is the distinct
    # queue_name values on solid_queue_jobs - so a queue this instance is configured to serve
    # doesn't appear until something has been enqueued onto it. Add the missing ones as empty.
    #
    # Prepended to ActiveJob::QueueAdapters::SolidQueueAdapter, in front of the gem's own
    # SolidQueueExt, by config/initializers/mission_control.rb.
    module AllConfiguredQueues
      def queues
        listed = super
        missing = Seek::Util.configured_queue_names - listed.map { |queue| queue[:name] }
        return listed if missing.empty?

        paused = SolidQueue::Pause.where(queue_name: missing).pluck(:queue_name)
        listed + missing.map { |name| { name: name, size: 0, active: paused.exclude?(name) } }
      end
    end
  end
end

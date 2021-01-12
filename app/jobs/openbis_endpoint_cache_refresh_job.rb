# job to periodically clear and refresh the cache
class OpenbisEndpointCacheRefreshJob < ApplicationJob
  queue_with_priority 3

  def perform(endpoint)
    return unless Seek::Config.openbis_enabled
    return unless endpoint&.persisted?
    endpoint.refresh_metadata
  end

  # jobs created if due, triggered by the scheduler.rb
  def self.queue_timed_jobs
    return unless Seek::Config.openbis_enabled
    OpenbisEndpoint.find_each do |endpoint|
      endpoint.create_refresh_metadata_job if endpoint.due_cache_refresh?
    end
  end
end

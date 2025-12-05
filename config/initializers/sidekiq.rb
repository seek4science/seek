# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
  
  # Configure concurrency
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i
  
  # Set default error handler
  config.error_handlers << lambda { |exception, context|
    Rails.logger.error("Sidekiq error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
  }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# Configure default Sidekiq options
Sidekiq.default_job_options = {
  'backtrace' => true,
  'retry' => false  # Match the delayed_job behavior where max_attempts was 1
}

# Map queue names to priorities
# Higher weight = higher priority
Sidekiq.options[:queues] = [
  ['default', 2],
  ['mailers', 2],
  ['authlookup', 2],
  ['remotecontent', 2],
  ['samples', 2],
  ['indexing', 2],
  ['templates', 2],
  ['datafiles', 2]
]

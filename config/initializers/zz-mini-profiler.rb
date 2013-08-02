if Rails.configuration.respond_to?(:enable_mini_profiler) && Rails.configuration.enable_mini_profiler
  require 'rack-mini-profiler'
  Rack::MiniProfilerRails.initialize!(Rails.application)
end

if defined?(Rack::MiniProfiler)

  # Don't profile the polling calls.
  Rack::MiniProfiler.config.pre_authorize_cb = lambda do |env|
    (env['PATH_INFO'] !~ /refresh/)
  end

  Rack::MiniProfiler.config.position = 'left'
  Rack::MiniProfiler.config.backtrace_threshold_ms = 5
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
end
# Try and avoid deadlocks
Delayed::Backend::ActiveRecord.configure do |config|
  config.reserve_sql_strategy = :default_sql
end

SEEK::Application.configure do

  Delayed::Worker.destroy_failed_jobs = false
  if Rails.env.development?
    Delayed::Worker.sleep_delay = 45
  else
    Delayed::Worker.sleep_delay = 3
  end

  Delayed::Worker.max_attempts = 1
  Delayed::Worker.max_run_time = 1.day
  Delayed::Worker.read_ahead = 20
  Delayed::Worker.backend = :active_record
  Delayed::Worker.default_queue_name = 'default'

  #Delayed::Worker.logger = Delayed::Worker.logger = ActiveSupport::BufferedLogger.new(Rails.root.join('log/worker.log'),Logger::INFO)
  #Delayed::Worker.logger.auto_flushing = 1
end

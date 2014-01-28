SEEK::Application.configure do

  Delayed::Worker.destroy_failed_jobs = false
  Delayed::Worker.sleep_delay = 3
  Delayed::Worker.max_attempts = 1
  Delayed::Worker.max_run_time = 1.day
  Delayed::Worker.read_ahead = 20
  Delayed::Worker.backend = :active_record
  Delayed::Worker.default_queue_name = 'default'

  #Delayed::Worker.logger = Delayed::Worker.logger = ActiveSupport::BufferedLogger.new(Rails.root.join('log/worker.log'),Logger::INFO)
  #Delayed::Worker.logger.auto_flushing = 1
end

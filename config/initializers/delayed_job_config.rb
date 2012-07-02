Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 3
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 1.hour
Delayed::Worker.backend = :active_record

#Delayed::Worker.logger = Delayed::Worker.logger = ActiveSupport::BufferedLogger.new(Rails.root.join('log/worker.log'),Logger::INFO)
#Delayed::Worker.logger.auto_flushing = 1

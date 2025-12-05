# module for handling interaction with Sidekiq workers
module Seek
  module Workers
    SIDEKIQ_PID_FILE = "#{Rails.root}/tmp/pids/sidekiq.pid".freeze
    
    def self.start
      return if running?
      
      queues = active_queues.join(',')
      command = "bundle exec sidekiq -d -e #{Rails.env} " \
                "-C config/sidekiq.yml " \
                "-P #{SIDEKIQ_PID_FILE} " \
                "-L #{Rails.root}/log/sidekiq.log"
      
      system(command)
    end

    def self.active_queues
      queues = [QueueNames::DEFAULT]
      queues << QueueNames::MAILERS
      queues << QueueNames::AUTH_LOOKUP if Seek::Config.auth_lookup_enabled
      queues << QueueNames::REMOTE_CONTENT if Seek::Config.cache_remote_files
      queues << QueueNames::SAMPLES if Seek::Config.samples_enabled
      queues << QueueNames::INDEXING if Seek::Config.solr_enabled
      queues << QueueNames::TEMPLATES if Seek::Config.isa_json_compliance_enabled
      queues << QueueNames::DATAFILES if Seek::Config.data_files_enabled
      queues
    end

    def self.stop
      if File.exist?(SIDEKIQ_PID_FILE)
        pid = File.read(SIDEKIQ_PID_FILE).to_i
        begin
          Process.kill('TERM', pid)
          # Wait for graceful shutdown
          10.times do
            sleep(1)
            break unless process_running?(pid)
          end
          # Force kill if still running
          Process.kill('KILL', pid) if process_running?(pid)
        rescue Errno::ESRCH
          # Process doesn't exist
        end
        File.delete(SIDEKIQ_PID_FILE) if File.exist?(SIDEKIQ_PID_FILE)
      end
    end

    def self.status
      if running?
        puts "Sidekiq is running (PID: #{File.read(SIDEKIQ_PID_FILE).strip})"
      else
        puts "Sidekiq is not running"
      end
    end

    def self.restart
      stop
      sleep(1)
      start
    end

    def self.running?
      if File.exist?(SIDEKIQ_PID_FILE)
        pid = File.read(SIDEKIQ_PID_FILE).to_i
        process_running?(pid)
      else
        false
      end
    end

    def self.process_running?(pid)
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH, Errno::EPERM
      false
    end

    def self.pids
      running? ? [File.read(SIDEKIQ_PID_FILE).to_i] : []
    end
  end
end

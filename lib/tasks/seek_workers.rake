# frozen_string_literal: true

# The seek:workers:* tasks manage the Solid Queue supervisor (bin/jobs), which forks and monitors the
# per-queue worker/dispatcher/scheduler subprocesses (config/queue.yml). They are the interface used
# by the Docker entrypoints, the deployment scripts and any external init scripts, abstracting the
# job backend away from those callers.
namespace :seek do
  namespace :workers do
    desc 'Start the Solid Queue supervisor in the background'
    task start: :environment do
      if (pid = Seek::Util.solid_queue_supervisor_pid)
        puts "Solid Queue supervisor is already running (pid #{pid})"
      else
        # Daemonise: a new process group detached from this task, writing to the Rails log, so bin/jobs
        # keeps running after the task returns. The supervisor records its own pid in
        # SolidQueue.supervisor_pidfile (config/initializers/solid_queue.rb), which stop/status read.
        log = Rails.application.config.paths['log'].first
        pid = Process.spawn('bundle', 'exec', 'bin/jobs',
                            chdir: Rails.root.to_s, pgroup: true,
                            in: File::NULL, out: [log, 'a'], err: [log, 'a'])
        Process.detach(pid)
        puts "Started Solid Queue supervisor in the background (pid #{pid})"
      end
    end

    desc 'Stop the Solid Queue supervisor'
    task stop: :environment do
      pid = Seek::Util.solid_queue_supervisor_pid
      if pid.nil?
        puts 'No Solid Queue supervisor is running'
      else
        Process.kill('TERM', pid)
        puts "Stopping Solid Queue supervisor (pid #{pid})..."
        # Wait (up to ~15s) for the supervisor to shut its workers down and remove its pidfile, so that
        # a following start (e.g. from restart) sees a clean state rather than the still-exiting process.
        30.times do
          break if Seek::Util.solid_queue_supervisor_pid.nil?

          sleep 0.5
        end
        if Seek::Util.solid_queue_supervisor_pid
          puts 'Solid Queue supervisor did not stop within 15s'
        else
          puts 'Solid Queue supervisor stopped'
        end
      end
    rescue Errno::ESRCH
      puts 'No Solid Queue supervisor is running' # exited between the check and the signal
    end

    desc 'Restart the Solid Queue supervisor'
    task restart: :environment do
      Rake::Task['seek:workers:stop'].invoke
      Rake::Task['seek:workers:start'].invoke
    end

    desc 'Report whether the Solid Queue supervisor is running'
    task status: :environment do
      pid = Seek::Util.solid_queue_supervisor_pid
      puts(pid ? "Solid Queue supervisor running (pid #{pid})" : 'Solid Queue supervisor is not running')
    end
  end
end

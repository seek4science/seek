module Seek
  module JobDashboard
    # Adds a duration column to the finished jobs table. Prepended to
    # MissionControl::Jobs::JobsHelper for the column heading, and rendered by
    # app/views/mission_control/jobs/jobs/finished/_job.html.erb.
    module FinishedJobDuration
      def attribute_names_for_job_status(status)
        status.to_s == 'finished' ? super + ['Duration'] : super
      end

      # Solid Queue deletes the claimed execution when a job finishes, so the time a job actually
      # started running is no longer recorded. This measures from when the job became due instead,
      # which also covers however long it then waited for a worker. Formatted as the single job
      # page formats its own Duration row, so the two read identically.
      def job_duration(job)
        return unless job.finished_at && job.scheduled_at

        "#{job.duration.round(3)} seconds"
      end
    end
  end
end

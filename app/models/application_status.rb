class ApplicationStatus < ApplicationRecord
    self.table_name = 'application_status'
    validates :running_jobs, presence: true
    before_create :validate_singleton

    def refresh
        alive_since = SolidQueue.process_alive_threshold.ago
        update(
            running_jobs: SolidQueue::Process.where(kind: 'Worker').where('last_heartbeat_at > ?', alive_since).count
         )
    end

    def search_enabled
        Seek::Config.solr_enabled
    end

    def self.instance
        record = ApplicationStatus.first
        if record.nil?
            record = ApplicationStatus.create(running_jobs: 0)
        end
        record
    end

    private

    def validate_singleton
        raise RuntimeError.new("There should only be 1 record created") if ApplicationStatus.count > 0
    end
end

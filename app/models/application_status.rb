class ApplicationStatus < ApplicationRecord
    self.table_name = 'application_status'
    validates :running_jobs, presence: true
    before_create :validate_singleton

    def refresh
        update(
            running_jobs: Seek::Util.delayed_job_pids.count
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

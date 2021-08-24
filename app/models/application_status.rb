class ApplicationStatus < ApplicationRecord
    self.table_name = 'application_status'
    validates :running_jobs, :soffice_running, presence: true
    before_create :validate_singleton

    def refresh
        update(
            running_jobs: Seek::Util.delayed_job_pids.count, 
            soffice_running:Seek::Config.soffice_available?(false),            
         )
    end

    def search_enabled
        Seek::Config.solr_enabled
    end

    def self.instance
        record = ApplicationStatus.first
        if record.nil?
            record = ApplicationStatus.create(running_jobs: 0, soffice_running: false)            
        end
        record
    end

    private

    def validate_singleton
        raise RuntimeError.new("There should only be 1 record created") if ApplicationStatus.count > 0
    end
end

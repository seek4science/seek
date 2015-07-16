# This job is only used for benchmarking data_file_auth_lookup table generation
# It is used in rake task seek_dev:benchmark_lookup_table_with_delayed_jobs

class DataFileAuthLookupJob < AuthLookupUpdateJob
  attr_reader :data_file_count

  def initialize(data_file_count)
    @data_file_count = data_file_count
  end

  private

  def perform_job(user)
    if user.is_a?(User)
      jobs = Delayed::Job.all
      job_info = jobs.count.to_s
      jobs.each do |job|
        job_info << job.handler.to_s
        job_info << job.id.to_s
      end
      Delayed::Job.logger.info("Process user #{user.id} on jobs #{job_info}")
      update_data_files_for_user user
    else
      Delayed::Job.logger.error("Unexepected type encountered: #{user.class.name}")
    end
  end

  def update_data_files_for_user(user)
    User.transaction(requires_new: :true) do
      DataFile.all.take(@data_file_count).each do |df|
        df.update_lookup_table(user)
      end
    end
    GC.start
  end

  def follow_on_job?
    AuthLookupUpdateQueue.count > 0
  end

end

class UnzipDataFilePersistJob < TaskJob
  queue_as QueueNames::DATAFILES

  attr_accessor :unzipper

  def perform(data_file, user, assay_ids: [])
    @unzipper = Seek::DataFiles::Unzipper.new(data_file)
    Rails.logger.info('Starting to persist data_files')
    time = Benchmark.measure do
      User.with_current_user(user) do
        datafiles = unzipper.persist(user).select(&:persisted?)
        unzipper.clear
        data_file.copy_assay_associations(datafiles, assay_ids) unless assay_ids.blank?
      end
    end

    Rails.logger.info("Benchmark for persist: #{time}")
  end

  def task
    arguments[0].unzip_persistence_task
  end

  def handle_error(exception)
    super
    @unzipper.clear if @unzipper
  end
  
  def timelimit
    2.hours
  end

end

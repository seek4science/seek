class SampleDataPersistJob < TaskJob
  queue_as QueueNames::SAMPLES

  attr_accessor :extractor

  def perform(data_file, sample_type, user, assay_ids: [])
    @extractor = Seek::Samples::Extractor.new(data_file, sample_type)
    Rails.logger.info('Starting to persist samples')
    time = Benchmark.measure do
      User.with_current_user(user) do
        samples = extractor.persist(user).select(&:persisted?)
        extractor.clear
        data_file.copy_assay_associations(samples, assay_ids) unless assay_ids.blank?
      end
    end

    Rails.logger.info("Benchmark for persist: #{time}")
  end

  def task
    arguments[0].sample_persistence_task
  end

  def handle_error(exception)
    super
    @extractor.clear if @extractor
  end

end

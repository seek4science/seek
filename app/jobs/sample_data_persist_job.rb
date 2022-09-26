class SampleDataPersistJob < TaskJob
  queue_as QueueNames::SAMPLES
  def perform(data_file, sample_type, assay_ids: [])
    extractor = Seek::Samples::Extractor.new(data_file, sample_type)

    Rails.logger.info('Starting to persist samples')

    time = Benchmark.measure do
      samples = extractor.persist.select(&:persisted?)
      extractor.clear
      data_file.copy_assay_associations(samples, assay_ids) unless assay_ids.blank?
    end

    Rails.logger.info("Benchmark for persist: #{time}")
  end

  def task
    arguments[0].sample_persistence_task
  end
end

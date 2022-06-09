class SampleDataPersistJob < TaskJob
  queue_as QueueNames::SAMPLES
  def perform(data_file, sample_type, assay_ids: [], contributor: nil)


    extractor = Seek::Samples::Extractor.new(data_file, sample_type)

    Rails.logger.info('Starting to persist samples')

    User.with_current_user(contributor.person) do
      time = Benchmark.measure do
        samples = extractor.persist.select(&:persisted?)
        extractor.clear
        @data_file.copy_assay_associations(samples, assay_ids) unless assay_ids.blank?
      end
    end

    Rails.logger.info("Benchmark for persist: #{time.to_s}")

  end

  def task
    arguments[0].sample_persistence_task
  end
end
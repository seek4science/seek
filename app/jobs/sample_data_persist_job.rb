class SampleDataPersistJob < TaskJob
  queue_as QueueNames::SAMPLES
  def perform(data_file, sample_type, assay_ids: [])
    extractor = Seek::Samples::Extractor.new(data_file, sample_type)

    extractor.persist

  end

  def task
    arguments[0].sample_persistence_task
  end
end
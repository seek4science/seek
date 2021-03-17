class SampleDataExtractionJob < TaskJob
  queue_as QueueNames::SAMPLES
  def perform(data_file, sample_type, persist = false, overwrite: false)
    extractor = Seek::Samples::Extractor.new(data_file, sample_type)

    if persist
      extractor.persist
    else
      extractor.clear
      extractor.extract(overwrite)
    end
  end

  def task
    arguments[0].sample_extraction_task
  end
end

class SampleDataExtractionJob < TaskJob
  queue_as QueueNames::SAMPLES

  attr_reader :extractor
  def perform(data_file, sample_type, overwrite: false)
    @extractor = Seek::Samples::Extractor.new(data_file, sample_type)
    @extractor.clear
    @extractor.extract(overwrite)
  end

  def task
    arguments[0].sample_extraction_task
  end

  def timelimit
    30.minutes
  end

  def handle_error(exception)
    super
    @extractor.clear if @extractor
  end
end

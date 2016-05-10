class SampleDataExtractionJob < SeekJob
  attr_reader :data_file, :sample_type, :contributor

  def initialize(data_file, sample_type, persist = false)
    @data_file = data_file
    @sample_type = sample_type
    @persist = persist
  end

  def perform_job(_)
    if @persist
      Seek::Samples::Extractor.new(@data_file, @sample_type).persist
    else
      Seek::Samples::Extractor.new(@data_file, @sample_type).extract
    end
  end

  def self.queue_name
    'sample_extraction'
  end

  def queue_name
    self.class.queue_name
  end

end

class SampleDataExtractionJob < SeekJob
  attr_reader :data_file_id, :sample_type_id, :persist

  def initialize(data_file, sample_type, persist = false)
    @data_file_id = data_file.id
    @sample_type_id = sample_type.id
    @persist = persist
  end

  def gather_items
    [data_file].compact
  end

  # either pending or running
  def self.in_progress?(data_file)
    [:pending, :running].include?(get_status(data_file))
  end

  def perform_job(item)
    extractor = Seek::Samples::Extractor.new(item, sample_type)

    if persist
      extractor.persist
    else
      extractor.clear
      extractor.extract
    end
  end

  def queue_name
    QueueNames::SAMPLES
  end

  def self.get_status(data_file)
    job = Delayed::Job.where("handler LIKE '%!ruby/object:SampleDataExtractionJob%'")
          .where("handler LIKE '%data_file_id: #{data_file.id}%'").last
    if job
      if job.locked_at
        if job.failed_at
          :failed
        else
          :running
        end
      else
        :pending
      end
    else
      nil
    end
  end

  private

  def data_file
    DataFile.find_by_id(data_file_id)
  end

  def sample_type
    SampleType.find_by_id(sample_type_id)
  end
end

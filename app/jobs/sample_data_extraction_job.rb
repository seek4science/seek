class SampleDataExtractionJob

  include DefaultJobProperties

  attr_reader :data_file, :sample_type, :contributor

  def self.get_status(data_file)
    job = Delayed::Job.where("handler LIKE '%!ruby/object:SampleDataExtractionJob%'").
        where("handler LIKE '%data_file_id: #{data_file.id}%'").last
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

  #either pending or running
  def self.in_progress?(data_file)
    [:pending,:running].include?(get_status(data_file))
  end

  def initialize(data_file, sample_type, persist = false)
    @data_file_id = data_file.id
    @data_file = data_file
    @sample_type = sample_type
    @persist = persist
  end

  def perform
    extractor = Seek::Samples::Extractor.new(@data_file, @sample_type)

    if @persist
      extractor.persist
    else
      extractor.clear
      extractor.extract
    end
  end

  def queue_job(priority = default_priority, time = default_delay.from_now)
    Delayed::Job.enqueue(self, priority: priority, queue: queue_name, run_at: time)
  end

  def default_priority
    1
  end

  def queue_name
    QueueName::SAMPLES
  end

end

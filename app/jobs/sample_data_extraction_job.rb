class SampleDataExtractionJob < ApplicationJob
  queue_as QueueNames::SAMPLES

  # either pending or running
  def self.in_progress?(data_file)
    [:pending, :running].include?(get_status(data_file))
  end

  def perform(data_file, sample_type, persist = false, overwrite: false)
    extractor = Seek::Samples::Extractor.new(data_file, sample_type)

    if persist
      extractor.persist
    else
      extractor.clear
      extractor.extract(overwrite)
    end
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
end

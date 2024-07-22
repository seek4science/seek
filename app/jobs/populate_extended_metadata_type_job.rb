class PopulateExtendedMetadataTypeJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::EXTENDED_METADATA_TYPES


  def perform(filename)
    Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(filename)
  rescue StandardError => e
    puts "MyJob failed with error: #{e.message}"
    raise e # Ensure the error is propagated
  end

  after_perform do |job|
    puts "after_perform"
    puts "job_id: #{job.provider_job_id}"
    puts "job.id: #{job.id}"

  end


end

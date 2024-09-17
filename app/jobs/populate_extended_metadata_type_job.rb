class PopulateExtendedMetadataTypeJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::EXTENDED_METADATA_TYPES


  def perform(filename)
    Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(filename)
  rescue StandardError => e
    raise e # Ensure the error is propagated
  end

  after_perform do |job|
    # clean up the filestore
    dir = Rails.root.join('filestore', 'emt_files')
    json_files = Dir.glob(File.join(dir, '**', '*.json'))
    json_files.each do |file|
      File.delete(file)
    end
  end
end

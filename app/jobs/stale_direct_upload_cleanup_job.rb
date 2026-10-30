# Deletes abandoned objects from the direct-upload staging area of the S3 storage backend. A file that a
# browser uploaded straight into the store but whose form was never submitted would otherwise stay there
# forever. Does nothing on the local backend, which has no staging area.
class StaleDirectUploadCleanupJob < ApplicationJob
  def perform
    return unless Seek::Storage.direct_upload_enabled?

    result = Seek::Storage::StaleUploadCleaner.new(logger: Rails.logger).run
    Rails.logger.info("[StaleDirectUploadCleanupJob] #{result.summary}")
  end
end

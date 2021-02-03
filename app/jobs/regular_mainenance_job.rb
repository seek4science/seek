# A job that runs regularly and performs certain general maintenance tasks
# the jobs is run periodically according to RUN_PERIOD
# short running, simple, maintenance operations can be added here, complex, or longer running operations should spawn a
# new job specific to the operation
class RegularMainenanceJob < ApplicationJob
  RUN_PERIOD = 8.hours.freeze
  BLOB_GRACE_PERIOD = 8.hours.freeze

  def perform
    clean_content_blobs
  end

  private

  # clean up dangling content blobs that are older than BLOB_GRACE_PERIOD and not associated with an asset
  def clean_content_blobs
    ContentBlob.where(asset:nil).where('created_at < ?', BLOB_GRACE_PERIOD.ago).select do |blob|
      Rails.logger.info("Cleaning up content blob #{blob.id}")
      blob.reload
      blob.destroy if blob.asset.nil?
    end
  end

end

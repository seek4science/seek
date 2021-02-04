# A job that runs regularly and performs certain general maintenance tasks
# the jobs is run periodically according to RUN_PERIOD
# short running, simple, maintenance operations can be added here, complex, or longer running operations should spawn a
# new job specific to the operation
class RegularMaintenanceJob < ApplicationJob
  RUN_PERIOD = 8.hours.freeze
  BLOB_GRACE_PERIOD = 8.hours.freeze
  USER_GRACE_PERIOD = 1.week.freeze

  def perform
    clean_content_blobs
    remove_unregistered_users
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

  # removes any users accounts that have not fully registered by creating an associated profile, and that were created
  # longer ago than the USER_GRACE_PERIOD
  def remove_unregistered_users
    User.where(person:nil).where('created_at < ?',USER_GRACE_PERIOD.ago).destroy_all
  end

end

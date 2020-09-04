class ContentBlobCleanerJob < ApplicationJob
  GRACE_PERIOD = 8.hours.freeze

  def perform
    ContentBlob.where('created_at < ?', GRACE_PERIOD.ago).select do |blob|
      Rails.logger.info("Cleaning up content blob #{blob.id}")
      blob.reload
      blob.destroy if blob.asset.nil?
    end
  end
end

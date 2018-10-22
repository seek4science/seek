# frozen_string_literal: true
class ActivityLog < ApplicationRecord
  serialize :data

  scope :no_spider, -> { where("(UPPER(user_agent) NOT LIKE '%SPIDER%' OR user_agent IS NULL)") }

  # returns items that have duplicates for a given action - NOTE that the result does not contain all the actual duplicates.
  scope :duplicates, ->(action) {
    select('activity_loggable_type, activity_loggable_id')
      .where("action = ? AND controller_name != 'sessions'", action)
      .group('activity_loggable_type, activity_loggable_id HAVING COUNT(*)>1')
  }
  after_create :send_notification
  after_save :clear_activity_caches

  def send_notification
    if Seek::Config.email_enabled && activity_loggable.try(:subscribable?) && activity_loggable.subscribers_are_notified_of?(action)
      SendImmediateEmailsJob.new(id).queue_job
    end
  end

  def self.remove_duplicate_creates
    duplicates = ActivityLog.duplicates 'create'
    duplicates.each do |duplicate|
      matches = ActivityLog.where(activity_loggable_id: duplicate.activity_loggable_id, activity_loggable_type: duplicate.activity_loggable_type, action: 'create').order('created_at ASC')
      (1...matches.count).to_a.each do |index|
        matches[index].destroy
      end
    end
  end

  def check_loggable_is_viewable
    result = true
    if activity_loggable && !activity_loggable.can_view?
      errors.add(:base, 'the asset is not viewable')
      result = false
    end
    result
  end

  #clears caches for the front page activity
  def clear_activity_caches
    if action == 'create' || action == 'update'
      Rails.cache.delete_matched(HomesHelper::CREATE_ACTIVITY_CACHE_PREFIX+'*')
    end

    if action == 'download'
      Rails.cache.delete_matched(HomesHelper::DOWNLOAD_ACTIVITY_CACHE_PREFIX+'*')
    end
  end
end

# frozen_string_literal: true
class ActivityLog < ApplicationRecord
  belongs_to :activity_loggable, polymorphic: true
  belongs_to :referenced, polymorphic: true
  belongs_to :culprit, polymorphic: true

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

  def can_render_link?
    if activity_loggable
      base = activity_loggable.can_view?
      if activity_loggable.class.name.include?('::Version')
        base && activity_loggable.parent&.can_view?
      elsif activity_loggable.is_a?(Snapshot)
        base && activity_loggable.resource&.can_view?
      else
        base
      end
    else
      false
    end
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

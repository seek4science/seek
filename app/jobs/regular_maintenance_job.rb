# A job that runs regularly and performs certain general maintenance tasks
# the jobs is run periodically according to RUN_PERIOD
# short running, simple, maintenance operations can be added here, complex, or longer running operations should spawn a
# new job specific to the operation

require 'rake'

class RegularMaintenanceJob < ApplicationJob
  RUN_PERIOD = 4.hours.freeze
  REMOVE_DANGLING_BLOB_GRACE_PERIOD = 8.hours.freeze
  REMOVE_DELETED_BLOB_GRACE_PERIOD = 24.hours.freeze
  REPO_GRACE_PERIOD = 8.hours.freeze
  USER_GRACE_PERIOD = 1.week.freeze
  MAX_ACTIVATION_EMAILS = 3
  RESEND_ACTIVATION_EMAIL_DELAY = 4.hours.freeze

  def perform
    remove_dangling_content_blobs
    remove_deleted_content_blobs
    clean_git_repositories
    resend_activation_emails
    remove_unregistered_users
    trim_session
    check_authlookup_consistency
  end

  private

  # clean up dangling content blobs that are older than REMOVE_DANGLING_BLOB_GRACE_PERIOD and not associated with an asset_id
  def remove_dangling_content_blobs
    ContentBlob.where(asset_id: nil).where('created_at < ?', REMOVE_DANGLING_BLOB_GRACE_PERIOD.ago).select do |blob|
      Rails.logger.info("Cleaning up content blob #{blob.id}")
      blob.reload
      blob.destroy if blob.asset.nil?
    end
  end

  def remove_deleted_content_blobs
    ContentBlob.where(deleted: true).where('created_at < ?', REMOVE_DELETED_BLOB_GRACE_PERIOD.ago).select do |blob|
      Rails.logger.info("Removing content blob #{blob.id} marked for deletion")

      # play safe and only delete if asset has gone even if flagged for deletion
      blob.destroy if blob.asset.nil?
    end
  end

  # Remove GitRepositories that were never used
  def clean_git_repositories
    Git::Repository.redundant.where('git_repositories.created_at < ?', REPO_GRACE_PERIOD.ago).select do |repo|
      Rails.logger.info("Cleaning up Git::Repository #{repo.id}")
      repo.destroy
    end
  end

  # removes any users accounts that have not fully registered by creating an associated profile, and that were created
  # longer ago than the USER_GRACE_PERIOD
  def remove_unregistered_users
    User.where(person: nil).where('created_at < ?', USER_GRACE_PERIOD.ago).destroy_all
  end

  # trims old sessions, using the db:sessions:trim task
  def trim_session
    Rails.application.load_tasks
    Rake::Task['db:sessions:trim'].invoke
  end

  # resends an activation email, for unactivated users that haven't received an email since RESEND_ACTIVATION_EMAIL_DELAY
  # and a total maximum of MAX_ACTIVATION_EMAILS (which will include the first one)
  def resend_activation_emails
    User.where.not(person: nil).where.not(activation_code: nil).each do |user|
      if user.person
        logs = user.person.activation_email_logs
        if logs.count < MAX_ACTIVATION_EMAILS && (logs.empty? || logs.last.created_at < RESEND_ACTIVATION_EMAIL_DELAY.ago)
          Mailer.activation_request(user).deliver_later
          ActivationEmailMessageLog.log_activation_email(user.person)
        end
      else
        Rails.logger.info("User with invalid person - #{user.id}")
      end
    end
  end

  # checks lookup_table_consistent? on each type for each user, and if not triggers a job to repopulate for that user
  # if not already queued
  def check_authlookup_consistency
    found_types = [].to_set
    items_for_queue = [].to_set
    User.where.not(person_id: nil).to_a.push(nil).each do |user|

      # will only deal with 1 type per user per run
      found = Seek::Util.authorized_types.find do |type|
        !type.lookup_table_consistent?(user)
      end

      next unless found.present?

      found_types << found
      missing = found.items_missing_from_authlookup(user)
      items_for_queue.merge(missing)
    end

    found_types.each(&:remove_invalid_auth_lookup_entries)
    AuthLookupUpdateQueue.enqueue(items_for_queue.to_a) unless items_for_queue.empty?
  end
end

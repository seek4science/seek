# A job that runs regularly and performs certain general maintenance tasks
# the jobs is run periodically according to RUN_PERIOD
# short running, simple, maintenance operations can be added here, complex, or longer running operations should spawn a
# new job specific to the operation

require 'rake'

class RegularMaintenanceJob < ApplicationJob
  RUN_PERIOD = 4.hours.freeze
  BLOB_GRACE_PERIOD = 8.hours.freeze
  USER_GRACE_PERIOD = 1.week.freeze
  MAX_ACTIVATION_EMAILS = 3
  RESEND_ACTIVATION_EMAIL_DELAY = 4.hours.freeze

  def perform
    clean_content_blobs
    resend_activation_emails
    remove_unregistered_users
    trim_session
  end

  private

  # clean up dangling content blobs that are older than BLOB_GRACE_PERIOD and not associated with an asset
  def clean_content_blobs
    ContentBlob.where(asset: nil).where('created_at < ?', BLOB_GRACE_PERIOD.ago).select do |blob|
      Rails.logger.info("Cleaning up content blob #{blob.id}")
      blob.reload
      blob.destroy if blob.asset.nil?
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
          MessageLog.log_activation_email(user.person)
        end
      else
        Rails.logger.info("User with invalid person - #{user.id}")
      end  
    end
  end
end

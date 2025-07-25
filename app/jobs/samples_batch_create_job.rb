# frozen_string_literal: true

class SamplesBatchCreateJob < TaskJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES
  include Seek::Samples::SamplesCommon

  def perform(sample_type, new_sample_params, send_email, user)
    results, errors = batch_create_samples(new_sample_params).values_at(:results, :errors)

    if send_email && Seek::Config::email_enabled && user
      project = sample_type.projects.first
      if sample_type.assays.empty?
        item_type = 'study'
        item_id = sample_type.studies.first
      else
        item_type = 'assay'
        item_id = sample_type.assays.first
      end

      Mailer.notify_user_after_spreadsheet_extraction(user, project, item_type, item_id, results, errors).deliver_now
    end
  end

  def task
    arguments[0].samples_batch_create_task
  end
end

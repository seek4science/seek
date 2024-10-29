# frozen_string_literal: true

class UpdateSampleMetadataJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  attr_accessor :sample_type, :user, :attribute_changes

  before_enqueue do |job|
    SampleType.find(job.arguments[0].id).set_lock
  end

  before_perform do |job|
    SampleType.find(job.arguments[0].id).set_lock
  end

  def perform(sample_type, user, attribute_changes = [])
    @sample_type = sample_type
    @user = user
    @attribute_changes = attribute_changes

    Seek::Samples::SampleMetadataUpdater.new(@sample_type, @user, @attribute_changes).update_metadata
  end
end

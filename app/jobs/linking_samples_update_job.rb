# Job responsible for updating the title of sample in the linking samples
class LinkingSamplesUpdateJob < ApplicationJob
  queue_as QueueNames::SAMPLES
  queue_with_priority 1

  def perform(sample)
    disable_authorization_checks do
      sample.refresh_linking_samples
    end
  end
end

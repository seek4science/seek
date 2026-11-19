# Clears the triple store, if one is configured, and then queues the RDF to be generated for every RDF capable item
class RdfRegenerateAllJob < ApplicationJob
  queue_as QueueNames::RDF
  def perform
    repository = Seek::Rdf::RdfRepository.instance
    repository.clear_all if repository.configured?

    failed = RdfGenerationQueue.enqueue_all
    Rails.logger.error("Error queuing RDF generation for #{failed.join(', ')}") if failed.any?
  end

  def timelimit
    1.hour
  end
end

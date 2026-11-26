# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'rightfield/rightfield'

namespace :seek_rdf do
  desc 'Clears the triple store, if one is configured, and queues background jobs to regenerate the RDF (including sending to the triple store) for every compatible item.'
  task(generate: :environment) do
    Seek::Rdf::RdfRepository.instance.clear_all
    failed = RdfGenerationQueue.enqueue_all
    puts("Error queuing RDF generation for #{failed.join(', ')} - see the log for details") if failed.any?
  end
end

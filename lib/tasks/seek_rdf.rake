# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'rightfield/rightfield'

namespace :seek_rdf do
  desc 'Queues background jobs, which will update or create the RDF (including sending to a configured triple store) for every compatible asset.'
  task(generate: :environment) do
    failed = RdfGenerationQueue.enqueue_all
    puts("Error queuing RDF generation for #{failed.join(', ')} - see the log for details") if failed.any?
  end
end

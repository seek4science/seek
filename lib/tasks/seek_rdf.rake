# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'rightfield/rightfield'

namespace :seek_rdf do
  desc 'Queues background jobs, which will update or create the RDF (including sending to a configured triple store) for every compatible asset.'
  task(generate: :environment) do
    Seek::Util.rdf_capable_types.sort_by(&:name).each do |type|
      begin
        RdfGenerationQueue.enqueue(type.all)
      rescue Exception => e
        puts("Error generating rdf for #{type.name}} - #{e.message}")
      end
    end
  end
end

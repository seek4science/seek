require 'rubygems'
require 'rake'
require 'rightfield/rightfield'

namespace :seek_rdf do

  desc "Queues background jobs, which will update or create the RDF (including sending to a configured triple store) for every compatible asset."
  task(:generate=>:environment) do
    Seek::Util.rdf_capable_types.sort_by(&:name).each do |type|
      type.find_each do |instance|
        begin
          RdfGenerationJob.new(instance,false).queue_job
        rescue Exception=>e
          puts("Error generating rdf for #{instance.class.name}:#{instance.id} - #{e.message}")
        end
      end
    end
  end
end

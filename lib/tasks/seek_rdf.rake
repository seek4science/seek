require 'rubygems'
require 'rake'
require 'rightfield/rightfield'

namespace :seek_rdf do

  task(:generate=>:environment) do
    Seek::Util.rdf_capable_types.sort_by(&:name).each do |type|
      type.all.each do |instance|
        begin
          puts "ID = #{instance.id} for #{type}"
          path = instance.save_rdf
          puts "Generated #{path} for #{type}:#{instance.id}"
        rescue Exception=>e
          puts("Error generating rdf for #{instance.class.name}:#{instance.id} - #{e.message}")
        end

      end
    end

  end
end

require 'rubygems'
require 'rake'
require 'rightfield/rightfield'

namespace :seek_rdf do

  task(:generate=>:environment) do
    tmpdir=File.join(Rails.root, "tmp", "rdf")
    if !File.exists?(tmpdir)
      FileUtils.mkdir_p(tmpdir)
    end

    Seek::Util.rdf_capable_types.each do |type|
      type.all.each do |instance|
        begin
          rdf = instance.to_rdf
          uuid = instance.respond_to?(:uuid) ? instance.uuid : UUIDTools::UUID.random_create.to_s
          filename="#{uuid}.rdf"
          path = File.join(tmpdir,filename)
          File.open(path,"w") do |f|
            f.write(rdf)
            f.flush
          end
          puts "Generated #{path} for #{type}:#{instance.id}"
        rescue Exception=>e
          puts("Error generating rdf for #{instance.class.name}:#{instance.id} - #{e.message}")
        end

      end
    end

  end
end

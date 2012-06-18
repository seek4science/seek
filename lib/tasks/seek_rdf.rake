require 'rubygems'
require 'rake'
require 'rightfield/rightfield'

namespace :seek_rdf do

  task(:generate=>:environment) do
    tmpdir=File.join(Dir.tmpdir, "seek-rdf")
    if !File.exists?(tmpdir)
      FileUtils.mkdir_p(tmpdir)
    end

    DataFile.all.each do |asset|
      if asset.is_extractable_spreadsheet? && asset.is_xls?
        begin
          rdf = asset.to_rdf

          filename="#{asset.uuid}.rdf"

          File.open(File.join(tmpdir, filename), "w") do |f|
            f.write(rdf)
          end
        rescue Exception=>e
          puts("Error generating rdf for #{asset.class.name}:#{asset.id} - #{e.message}")
        end

      end
    end

  end
end

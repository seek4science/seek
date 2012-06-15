require 'rubygems'
require 'rake'
require 'rightfield/rightfield'

namespace :seek_rdf do

  task(:generate=>:environment) do
      tmpdir=File.join(Dir.tmpdir,"seek-rdf")
      if !File.exists?(tmpdir)
        FileUtils.mkdir_p(tmpdir)
      end

      DataFile.all.each do |df|
      if df.is_extractable_spreadsheet?
        rdf = df.to_rdf

        filename="#{df.uuid}.rdf"
        File.open(File.join(tmpdir,filename),"w") do |f|
          f.write(rdf)
        end
        end
      end

  end
end

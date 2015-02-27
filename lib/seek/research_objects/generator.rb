module Seek::ResearchObjects

  class Generator
    include Singleton
    include Utils

    # :call-seq
    # generate(investigation,file) -> File
    # generate(investigation) ->
    #
    # generates an RO-Bundle for the given investigation.
    # if a file objects is passed in then the bundle in created to the file, overwriting previous content
    # if no file is provided, then a temporary file is created
    # in both cases the file is returned
    #
    def generate(investigation,file=nil)
      file ||= temp_file("ro-bundle.zip")
      ROBundle::File.create(file) do |bundle|
        bundle.created_by=create_agent
        gather_entries(investigation).each do |entry|
          describe_metadata(bundle,entry)
        end

        bundle.created_on=Time.now
      end

      return file
    end

    private

    def gather_entries(investigation)
      entries = [investigation] + [investigation.studies] + [investigation.studies.collect{|study| study.assays}]
      entries.flatten
    end

    def describe_metadata bundle, item
      tmpfile = temp_file("metadata.rdf","ro-bundle-item-metadata")
      tmpfile << item.to_rdf
      tmpfile.close

      targetpath = File.join(path_for_item(item),"metadata.rdf")
      bundle.add(targetpath,tmpfile,:aggregate=>false)

      an = ROBundle::Annotation.new(uri_for_item(item),targetpath)
      an.created_on=Time.now
      an.created_by=create_agent
      bundle.add_annotation(an)
    end

  end
end
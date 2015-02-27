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
        describe_metadata(bundle,investigation)
        investigation.studies.each do |study|
          describe_metadata(bundle,study)
          study.assays.each do |assay|
            describe_metadata(bundle,assay)
          end
        end

        bundle.created_on=Time.now
      end

      return file
    end

    private

    def describe_metadata bundle, item
      Seek::ResearchObjects::MetadataJson.add_to_bundle(bundle, item)
    end

  end
end
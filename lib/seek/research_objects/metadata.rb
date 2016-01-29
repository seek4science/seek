module Seek
  module ResearchObjects
    # abstract super class for storing metadata for an item.
    # the metadata, in text format, should be defined in an implementation of #metadata_content
    # the metadata filename should be defined in an implementation of #metadata_filename
    class Metadata
      include Seek::ResearchObjects::Utils

      def store(bundle, item, parents = [])
        tmpfile = Tempfile.new(metadata_filename)
        tmpfile << metadata_content(item, parents)
        tmpfile.close

        folder_path = item.research_object_package_path(parents)
        targetpath = folder_path + metadata_filename

        bundle.add(targetpath, tmpfile, aggregate: true)
        bundle.commit

        an = ROBundle::Annotation.new('/' + item.research_object_package_path(parents), targetpath)
        an.created_on = Time.now
        bundle.manifest.annotations << an
      end
    end
  end
end

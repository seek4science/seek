module Seek
  module ResearchObjects
    # abstract super class for storing metadata for an item.
    # the metadata, in text format, should be defined in an implementation of #metadata_content
    # the metadata filename should be defined in an implementation of #metadata_filename
    class Metadata
      include Seek::ResearchObjects::Utils

      def store(bundle, item)
        tmpfile = Tempfile.new(metadata_filename)
        tmpfile << metadata_content(item)
        tmpfile.close

        folder_path = item.research_object_package_path
        targetpath = folder_path + metadata_filename

        bundle.add(targetpath, tmpfile, aggregate: true)
        bundle.commit

        an = ROBundle::Annotation.new('/' + item.research_object_package_path, targetpath)
        an.created_on = Time.now
        bundle.manifest.annotations << an
      end
    end
  end
end

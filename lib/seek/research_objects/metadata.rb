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

        targetpath = File.join(item.research_object_package_path, metadata_filename)
        bundle.add(targetpath, tmpfile, aggregate: false)
        bundle.commit

        an = ROBundle::Annotation.new(item_uri(item), targetpath)
        an.created_on = Time.now
        an.created_by = create_agent
        bundle.add_annotation(an)
      end

      def item_uri item
        uri = item.rdf_resource.to_uri.to_s
        uri << "?version=#{item.version}" if item.respond_to?(:version)
        uri
      end
    end
  end
end

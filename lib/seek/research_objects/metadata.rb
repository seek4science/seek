module Seek::ResearchObjects
  class Metadata
    include Seek::ResearchObjects::Utils

    def store(bundle, item)
      tmpfile = temp_file(metadata_filename, 'ro-bundle-item-metadata')
      tmpfile << metadata_content(item)
      tmpfile.close

      targetpath = File.join(item.package_path, metadata_filename)
      bundle.add(targetpath, tmpfile, aggregate: false)

      an = ROBundle::Annotation.new(item.rdf_resource.to_uri.to_s, targetpath)
      an.created_on = Time.now
      an.created_by = create_agent
      bundle.add_annotation(an)
    end
  end
end

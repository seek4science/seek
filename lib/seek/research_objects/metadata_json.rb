module Seek::ResearchObjects
  class MetadataJson
    extend Utils

    def self.add_to_bundle(bundle, item)
      tmpfile = temp_file("metadata.json","ro-bundle-item-metadata")
      tmpfile << describe(item)
      tmpfile.close

      targetpath = File.join(path_for_item(item),"metadata.json")
      bundle.add(targetpath,tmpfile,:aggregate=>false)

      an = ROBundle::Annotation.new(uri_for_item(item),targetpath)
      an.created_on=Time.now
      an.created_by=create_agent
      bundle.add_annotation(an)
    end

    def self.describe(item)
      json = {id:item.id, title:item.title, description:item.description}
      json[:contributor]=create_agent(item.contributor)
      json[:assay_type]=item.assay_type_uri if item.respond_to?(:assay_type_uri)
      json[:technology_type]=item.assay_type_uri if item.respond_to?(:technology_type_uri)

      JSON.pretty_generate(json)
    end

  end
end
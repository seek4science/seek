require 'libxml'

module Seek
  module ModelProcessing
    include ModelTypeDetection

    def extract_model_parameters_and_values model
      parser = LibXML::XML::Parser.file(model.content_blob.filepath)
      doc = parser.parse
      doc.root.namespaces.default_prefix="sbml"
      params={}
      doc.find("//sbml:listOfParameters/sbml:parameter").each do |node|
        value = node.attributes["value"] || nil
        params[node.attributes["id"]]=value
      end
      params
    end
  end
end
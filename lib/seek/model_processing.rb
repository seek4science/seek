require 'libxml'

module Seek
  module ModelProcessing
    include ModelTypeDetection

    #return a hash of parameters names as a key, along with their values, extracted from SBML
    def parameters_and_values model=self
      return [] if !model.is_sbml?
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

    #returns an array of species ID and NAME extracted from SBML
    def species model=self
      return [] if !model.is_sbml?
      parser = LibXML::XML::Parser.file(model.content_blob.filepath)
      doc = parser.parse
      doc.root.namespaces.default_prefix="sbml"
      species=[]
      doc.find("//sbml:listOfSpecies/sbml:species").each do |node|
        species << node.attributes["name"]
        species << node.attributes["id"]
      end
      species.select{|s| !s.blank?}.uniq
    end
  end
end
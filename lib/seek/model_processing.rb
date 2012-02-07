require 'libxml'

module Seek
  module ModelProcessing
    include ModelTypeDetection

    #return a hash of parameters names as a key, along with their values, extracted from SBML
    def parameters_and_values model=self
      if model.is_sbml?
        parameters_and_values_from_sbml model
      elsif model.is_dat?
        parameters_and_values_from_dat model
      else
        {}
      end
    end

    #returns an array of species ID and NAME extracted from SBML or JWS DAT
    def species model=self
      if model.is_sbml?
        species_from_sbml model
      elsif model.is_dat?
        species_from_dat model
      else
        []
      end
    end

    private

    def species_from_sbml model
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

    def species_from_dat model
      species = []
      contents = open(model.content_blob.filepath).read
      start_tag = "begin initial conditions"
      start=contents.index(start_tag)
      unless start.nil?
        last = contents.index("end initial conditions")
        unless last.nil?
           interesting_bit = (contents[start+start_tag.length..last-1]).strip
           unless interesting_bit.blank?
             interesting_bit.each_line do |line|
               unless line.index("[").nil?
                 species << line.gsub(/\[.*/,"").strip
               end
             end
           end
        end
      end
      species
    end
    def parameters_and_values_from_sbml model
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

  def parameters_and_values_from_dat model
      params_and_values = {}
      contents = open(model.content_blob.filepath).read
      start_tag = "begin parameters"
      start=contents.index(start_tag)
      unless start.nil?
        last = contents.index("end parameters")
        unless last.nil?
           interesting_bit = (contents[start+start_tag.length..last-1]).strip
           unless interesting_bit.blank?
             interesting_bit.each_line do |line|
               unless line.index("=").nil?
                 p_and_v = line.split("=")
                 params_and_values[p_and_v[0].strip]=p_and_v[1].strip
               end
             end
           end
        end
      end
      params_and_values
    end
  end
end
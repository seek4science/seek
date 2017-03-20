require 'rest_client'
require 'libxml'
require 'cgi'

module Seek
  class SabiorkWebservices
    def get_compound_annotation(compound_name)
      url = URI.encode(webservice_base_url + 'compounds?compoundName=')
      compound_name = URI.escape(compound_name, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      url.concat(compound_name)
      doc = get_xml_doc url
      compound_annotations = { 'synonyms' => [], 'chebi_ids' => [], 'kegg_ids' => [] }

      unless doc.blank? || (doc.find('//Compound/sabioID').collect.blank?)
        # name
        doc.find('//Compound/Names/name').collect do |node|
          if node['type'] == 'Recommended'
            compound_annotations['recommended_name'] = node.content
          else
            compound_annotations['synonyms'] |= [node.content]
          end
        end
        # return nil if the xml doesnt contain the recommended name
        return nil if compound_annotations['recommended_name'].blank?
        # sabiork id
        compound_annotations['sabiork_id'] = doc.find_first('//Compound/sabioID').content
        # chebi_ids
        doc.find('//Compound/ChebiIDs/chebi').collect do |node|
          compound_annotations['chebi_ids'] |= [node.content]
        end
        # kegg_ids
        doc.find('//Compound/KEGGIDs/kegg').collect do |node|
          compound_annotations['kegg_ids'] |= [node.content]
        end
        compound_annotations
      else
        return nil
      end
     end

    def webservice_base_url
      Seek::Config.sabiork_ws_base_url
    end

    def get_xml_doc(url)
      response = RestClient.get(url)
      parser = LibXML::XML::Parser.string(response, encoding: LibXML::XML::Encoding::UTF_8)
      doc = parser.parse
      doc
    rescue
      return nil
    end
  end
end

module Seek
  module JWS
    #For handling the parameters and XML responses from the JWS Online annotator and builder
    module APIHandling

      def jws_post_parameters
        ["nameToSearch", "urnsearchbox", "selectedSymbol", "urnsearchboxReaction", "selectedReactionSymbol", "assignmentRules", "annotationsReactions", "annotationsSpecies", "modelname", "parameterset", "kinetics", "functions", "initVal", "reaction", "events", "steadystateanalysis", "plotGraphPanel", "plotKineticsPanel","citationURL","citationURN","modelURN","creationTime","modificationTime","authors","TOD","notes"]
      end

      def extract_applet body
        doc = Hpricot(body)
        element = doc.search("//object").first
        element.at("param").before(%!<param name="codebase" value="#{BASE_URL}"/>!)
        element.to_s
      end

      def process_response_body body

        parser = LibXML::XML::Parser.string(body, :encoding => LibXML::XML::Encoding::UTF_8)
        doc = parser.parse
        param_values = extract_main_parameters doc

        saved_file = determine_saved_file doc
        objects_hash = create_objects_hash doc
        fields_with_errors = find_reported_errors doc
        attribution_annotations = find_attribution_annotations param_values

        return param_values, attribution_annotations, saved_file, objects_hash, fields_with_errors
      end

      def extract_main_parameters doc
        params={}
        doc.find("//form[@id='main']/*/parameter").each do |node|
          unless node.attributes['id'].nil?
            id=node.attributes['id']
            params[id]=node.content.strip
          end
        end

        #FIXME: this is only required until the parameters for attributions are moved to the parameters block
        doc.find("//form[@id='main']/parameter").each do |node|
          unless node.attributes['id'].nil?
            id=node.attributes['id']
            params[id]=node.content.strip
          end
        end

        params
      end

      def determine_saved_file doc
        file=nil
        node = doc.find_first("//form[@id='simulate']/parameters/parameter[@id='savedfile']")
        unless node.nil?
          file=node.content.strip
        end
        file
      end

      def find_reported_errors doc
        errors=[]

        doc.find("//errorinfo/error").each do |error_report|
          value=error_report.content.strip
          name=error_report.attributes['id']
          errors << name unless value=="0"
        end

        #FIXME: temporary fix to as the builder validator always reports a problem with "functions"
        errors.delete("functions")

        errors
      end

      def create_objects_hash doc
        objects_hash = {}
        doc.find("//form[@id='main']/objects/object").each do |node|
          id=node.attributes['id']
          if ["reactionImage", "kineticsImage"].include?(id)
            url=node.content.strip
            url = BASE_URL + "JWSconstructor_panels/" + url
            objects_hash[id]=url
          end
        end
        objects_hash
      end

      def process_annotator_response_body body
        parser = LibXML::XML::Parser.string(body, :encoding => LibXML::XML::Encoding::UTF_8)
        doc = parser.parse

        params_hash = extract_main_parameters doc
        saved_file = determine_saved_file doc
        fields_with_errors = find_reported_errors doc
        search_results = extract_search_results doc
        cached_annotations = extract_cached_annotations doc
        assigned_species_annotations, assigned_reactions_annotations = extract_assigned_annotations doc
        attribution_annotations = find_attribution_annotations params_hash

        return params_hash, attribution_annotations, assigned_species_annotations, assigned_reactions_annotations, search_results, cached_annotations, saved_file, fields_with_errors
      end

      def find_attribution_annotations param_values
        annotations = AttributionAnnotations.new

        annotations.model_name=param_values["modelname"] || ""
        annotations.citation_url=param_values["citationURL"] || ""
        annotations.citation_urn=param_values["citationURN"] || ""
        annotations.model_urn=param_values["modelURN"] || ""
        annotations.authors=param_values["authors"] || ""
        annotations.creation_date=param_values["creationDate"] || ""
        annotations.modification_date=param_values["modificationDate"]
        annotations.terms_of_distribution=param_values["TOD"] || ""
        annotations.notes = param_values["notes"] || ""

        annotations
      end

      def extract_cached_annotations doc
        extract_annotation_symbols "//annotations/cached", doc
      end

      def extract_search_results doc
        search_node=doc.find_first("//annotations/search")
        search_results = nil
        if search_node && search_node.find_first("parameter[@id='nameToSearch']") && search_node.find_first("parameter[@id='selected']")
          search_results = SearchResults.new

          search_results.search_term = search_node.find_first("parameter[@id='nameToSearch']").content.strip

          search_results.selected_symbol = search_node.find_first("parameter[@id='selected']").content.strip

          search_results.error_code = search_node.find_first("parameter[@id='errorCode']").content.strip

          search_results.search_status = search_node.find_first("parameter[@id='searchStatus']").content.strip

          search_symbols = extract_annotation_symbols("results", search_node)
          results = search_symbols.keys.empty? ? [] : search_symbols[search_symbols.keys.first]
          search_results.results=results
        end
        search_results
      end

      def extract_assigned_annotations doc
        species_names, reaction_names = extract_species_and_reaction_names doc
        species_annotation_hash = extract_annotation_symbols "//annotations/assigned/species", doc
        species_annotation_hash = synchronise_hash species_names, species_annotation_hash

        reactions_annotation_hash = extract_annotation_symbols "//annotations/assigned/reactions", doc
        reactions_annotation_hash = synchronise_hash reaction_names, reactions_annotation_hash

        return species_annotation_hash, reactions_annotation_hash

      end

      def extract_annotation_symbols root_xpath, doc
        root_xpath += "/" unless root_xpath.end_with? "/"
        xpath=root_xpath + "symbol"
        symbols={}
        doc.find(xpath).each do |symbol|
          symbols[symbol.attributes["id"]] = extract_triplets(symbol)
        end
        symbols
      end

      def extract_triplets symbol
        symbol.find("triplet").collect do |triplet|
          full_name = triplet.find_first("ReadName").content
          urn = triplet.find_first("URN").content
          qualifier = triplet.find_first("Qualifier").content
          AnnotationTriplet.new full_name, urn, qualifier
        end
      end

      def extract_species_and_reaction_names doc
        species = []
        reactions = []
        species_names_node = doc.find_first("//speciesNames")
        species_names_node.children.each do |child|
          if !child.nil? && child.name == "name"
            species << child.content.strip
          end
        end unless species_names_node.nil?

        reaction_names_node = doc.find_first("//reactionsNames")
        reaction_names_node.children.each do |child|
          if !child.nil? && child.name == "name"
            reactions << child.content.strip
          end
        end unless reaction_names_node.nil?

        return species, reactions
      end

      def synchronise_hash keys, hash, default=[]
        (hash.keys - keys).each { |key| hash.delete(key) }
        keys.each do |key|
          hash[key]=default unless hash.has_key?(key)
        end
        hash
      end

      class AnnotationTriplet
        attr_accessor :full_name, :urn, :qualifier

        def initialize full_name, urn, qualifier
          @full_name=full_name
          @urn=urn
          @qualifier=qualifier
        end
      end

      class AttributionAnnotations
        attr_accessor :citation_url, :citation_urn, :model_urn, :authors, :creation_date, :modification_date, :terms_of_distribution, :notes, :model_name

        def initialize
          @authors = []
        end

        def authors_encoded
          str=""
          @authors.each do |a|
            str << a << "\\n"
          end
          str
        end

        def authors= authors
          if authors.kind_of?(Array)
            @authors = authors
          else
            @authors = authors.split("\\n")
          end
        end
      end

      class SearchResults
        attr_accessor :search_term, :selected_symbol, :results, :search_status, :error_code

        def initialize
          @results = []
        end
      end

    end
  end
end

module Seek
  module JWS
    class Annotator
      include APIHandling

      def annotator_url
        "#{Seek::JWS::BASE_URL}JWSconstructor_panels/Annotator_xml.jsp"
      end

      def annotate params

        param_translation={"species_selected_symbol"=>"selectedSymbol",
                           "species_search_box"=>"urnsearchbox",
                           "reactions_selected_symbol"=>"selectedReactionSymbol",
                           "reactions_search_box"=>"urnsearchboxReaction"}

        param_translation.keys.each do |key|
          new_key = param_translation[key]
          params[new_key]=params[key]
        end

        form_data = {}
        jws_post_parameters.each do |p|
          form_data[p]=params[p] if params.has_key?(p)
        end

        response = Net::HTTP.post_form(URI.parse(annotator_url), form_data)

        if response.instance_of?(Net::HTTPInternalServerError)
          raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
        end

        process_annotator_response_body(response.body)

      end



    end
  end
end
